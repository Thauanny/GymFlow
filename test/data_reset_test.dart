import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/core/theme/app_theme.dart';
import 'package:gymflow/core/utils/format.dart';
import 'package:gymflow/data/backup/backup_service.dart';
import 'package:gymflow/data/backup/data_reset.dart';
import 'package:gymflow/data/equipment/equipment_catalog.dart';
import 'package:gymflow/data/storage/key_value_store.dart';
import 'package:gymflow/models/labels.dart';
import 'package:gymflow/state/app_dependencies.dart';
import 'package:gymflow/state/nav_cubit.dart';
import 'package:gymflow/ui/features/progress/weight_chart.dart';
import 'package:gymflow/ui/features/settings/settings_page.dart';
import 'package:gymflow/ui/shell/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DataResetService', () {
    late MemoryStore store;
    late int reloads;
    late DataResetService service;

    setUp(() async {
      store = MemoryStore();
      reloads = 0;
      service = DataResetService(store, () => reloads++);
      for (final k in backupKeys) {
        await store.setString(k, 'x');
      }
    });

    Set<String> kept() => {
      for (final k in backupKeys)
        if (store.get(k) != null) k,
    };

    test('treinos: só a semana, o histórico e a divisão saem', () async {
      await service.reset(ResetScope.workouts);
      expect(backupKeys.toSet().difference(kept()), {
        'workouts',
        'train_days',
        'workout_history',
        'day_settings',
        'evolution_cycle',
      });
      expect(reloads, 1);
    });

    test('máquinas e exercícios: só equipamentos saem', () async {
      await service.reset(ResetScope.equipment);
      expect(backupKeys.toSet().difference(kept()), {
        'equip2',
        'dumbbells',
        'avoid_items',
      });
      expect(reloads, 1);
    });

    test('progresso: só histórico e cargas saem', () async {
      await service.reset(ResetScope.progress);
      expect(backupKeys.toSet().difference(kept()), {'logs', 'loads'});
      expect(reloads, 1);
    });

    test('treinos e progresso: treinos mais histórico e cargas', () async {
      await service.reset(ResetScope.workoutsAndProgress);
      expect(backupKeys.toSet().difference(kept()), {
        'workouts',
        'train_days',
        'workout_history',
        'day_settings',
        'evolution_cycle',
        'logs',
        'loads',
      });
      expect(reloads, 1);
    });

    test('peso corporal: só os registros de peso saem', () async {
      await service.reset(ResetScope.weight);
      expect(backupKeys.toSet().difference(kept()), {'weights'});
      expect(reloads, 1);
    });

    test('tudo: nenhuma chave do app sobra', () async {
      await service.reset(ResetScope.all);
      expect(kept(), isEmpty);
      expect(reloads, 1);
    });
  });

  group('com o app carregado', () {
    Future<AppDependencies> withData() async {
      SharedPreferences.setMockInitialValues({});
      final d = await AppDependencies.create();
      d.equipment.setAll({for (final i in equipItems) i.id});
      d.equipment.save();
      d.planner.setDays({1, 3, 5});
      await d.planner.generateWeek();
      d.planner.commit(replaceDays: true);
      await d.planActions.changePlan(); // cria um plano anterior
      d.progress.addWeight(70);
      // treino feito, com carga (a carga é guardada no progresso)
      final done = d.workouts.state.workouts.first;
      for (final i in done.items) {
        i.setsDone = i.sets;
        i.kg = 20;
      }
      d.progress.finish(done, 45);
      await d.planner.generateWeek(); // deixa um rascunho não salvo
      return d;
    }

    test('apagar treinos mantém equipamentos, peso e progresso', () async {
      final d = await withData();
      expect(d.workouts.state.workouts, isNotEmpty);
      expect(d.workouts.state.archive, isNotEmpty);
      expect(d.planner.state.drafts, isNotEmpty);

      await d.dataReset.reset(ResetScope.workouts);

      expect(d.workouts.state.workouts, isEmpty);
      expect(d.workouts.state.archive, isEmpty);
      expect(d.workouts.state.trainDays, isEmpty);
      expect(d.planner.state.drafts, isEmpty);
      expect(d.equipment.state.saved, isNotEmpty);
      expect(d.progress.state.weights, hasLength(1));
      expect(d.progress.state.logs, hasLength(1));
    });

    test(
      'apagar só o progresso mantém treinos, planos, peso e equipamentos',
      () async {
        final d = await withData();
        expect(d.progress.state.logs, isNotEmpty);
        expect(d.progress.state.loads, isNotEmpty);

        await d.dataReset.reset(ResetScope.progress);

        expect(d.progress.state.logs, isEmpty);
        expect(d.progress.state.trainedDays, isEmpty);
        expect(d.progress.state.loads, isEmpty);
        expect(d.workouts.state.workouts, isNotEmpty);
        expect(d.workouts.state.archive, isNotEmpty);
        expect(d.progress.state.weights, hasLength(1));
        expect(d.equipment.state.saved, isNotEmpty);
      },
    );

    test('apagar treinos e progresso mantém só equipamentos e peso', () async {
      final d = await withData();
      await d.dataReset.reset(ResetScope.workoutsAndProgress);

      expect(d.workouts.state.workouts, isEmpty);
      expect(d.workouts.state.archive, isEmpty);
      expect(d.planner.state.drafts, isEmpty);
      expect(d.progress.state.logs, isEmpty);
      expect(d.progress.state.trainedDays, isEmpty);
      expect(d.progress.state.loads, isEmpty);
      expect(d.progress.state.weights, hasLength(1));
      expect(d.equipment.state.saved, isNotEmpty);
    });

    test('apagar peso corporal não mexe em treinos nem progresso', () async {
      final d = await withData();
      await d.dataReset.reset(ResetScope.weight);

      expect(d.progress.state.weights, isEmpty);
      expect(d.progress.state.logs, hasLength(1));
      expect(d.workouts.state.workouts, isNotEmpty);
      expect(d.equipment.state.saved, isNotEmpty);
    });

    test('apagar máquinas mantém os treinos e o progresso', () async {
      final d = await withData();
      await d.dataReset.reset(ResetScope.equipment);

      expect(d.equipment.state.saved, isEmpty);
      expect(d.equipment.state.available, isEmpty);
      expect(d.workouts.state.workouts, isNotEmpty);
      expect(d.progress.state.logs, hasLength(1));
    });

    test('apagar tudo zera o app', () async {
      final d = await withData();
      await d.dataReset.reset(ResetScope.all);

      expect(d.workouts.state.workouts, isEmpty);
      expect(d.equipment.state.saved, isEmpty);
      expect(d.progress.state.weights, isEmpty);
      expect(d.progress.state.logs, isEmpty);
    });
  });

  testWidgets('configurações: confirmar apaga os treinos', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final d = (await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({});
      final d = await AppDependencies.create();
      d.equipment.setAll({for (final i in equipItems) i.id});
      d.equipment.save();
      d.planner.setDays({1, 3});
      await d.planner.generateWeek();
      d.planner.commit(replaceDays: true);
      return d;
    }))!;

    await tester.pumpWidget(
      d.provide(
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Apagar treinos'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Apagar treinos'));
    await tester.pump();
    await tester.tap(find.text('Apagar treinos'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Apagar todos os treinos?'), findsOneWidget);

    // cancelar não apaga nada
    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(d.workouts.state.workouts, isNotEmpty);

    await tester.tap(find.text('Apagar treinos'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Apagar treinos'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(d.workouts.state.workouts, isEmpty);
    expect(
      find.text('Treinos apagados. O histórico e o progresso foram mantidos.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 4)); // deixa o aviso sumir
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('Início e Progresso mostram só o que sobrou', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final d = (await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({});
      final d = await AppDependencies.create();
      d.equipment.setAll({for (final i in equipItems) i.id});
      d.equipment.save();
      d.planner.setDays({1, 3});
      await d.planner.generateWeek();
      d.planner.commit(replaceDays: true);
      d.progress.addWeight(70);
      d.progress.finish(d.workouts.state.workouts.first, 45);
      return d;
    }))!;

    await tester.pumpWidget(
      d.provide(
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: const AppShell(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    const noLogs = 'Nenhum treino registrado ainda.';
    const noWeight = 'Sem registros ainda.';
    // linha do histórico: "dd/mm/aaaa · N exercícios"
    final aLog = find.textContaining(formatDate(DateTime.now()));

    // as páginas são listas preguiçosas: rola até o fim para montar o rodapé
    Future<void> toEnd() async {
      final list = find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .hitTestable()
          .first;
      for (var i = 0; i < 3; i++) {
        await tester.drag(list, const Offset(0, -3000));
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    Future<void> reset(ResetScope scope) async {
      await tester.runAsync(() => d.dataReset.reset(scope));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await toEnd();
    }

    // início: o treino feito aparece no histórico
    await toEnd();
    expect(aLog, findsOneWidget);
    expect(find.text(noLogs), findsNothing);

    // apagar só os treinos: o histórico continua no Início
    await reset(ResetScope.workouts);
    expect(aLog, findsOneWidget);
    expect(find.text(noLogs), findsNothing);

    // treinos e progresso: o histórico some do Início
    await reset(ResetScope.workoutsAndProgress);
    expect(aLog, findsNothing);
    expect(find.text(noLogs), findsOneWidget);

    // progresso: o peso continua até apagar o peso corporal
    d.nav.go(AppTab.progress);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await toEnd();
    expect(find.byType(WeightChart), findsOneWidget);
    expect(find.text(noWeight), findsNothing);
    await reset(ResetScope.weight);
    expect(find.byType(WeightChart), findsNothing);
    expect(find.text(noWeight), findsOneWidget);
  });

  testWidgets(
    'apagar só o progresso limpa o histórico e mantém o treino de hoje',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final today = DateTime.now().weekday;
      final d = (await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues({});
        final d = await AppDependencies.create();
        d.equipment.setAll({for (final i in equipItems) i.id});
        d.equipment.save();
        d.planner.setDays({today});
        await d.planner.generateWeek();
        d.planner.commit(replaceDays: true);
        d.progress.finish(d.workouts.state.workouts.first, 45);
        return d;
      }))!;

      await tester.pumpWidget(
        d.provide(
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: const AppShell(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      final hero = find.text('HOJE · ${weekdayFull[today - 1].toUpperCase()}');
      expect(hero, findsOneWidget);

      await tester.runAsync(() => d.dataReset.reset(ResetScope.progress));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // o treino de hoje continua; o histórico some
      expect(hero, findsOneWidget);
      expect(d.workouts.state.workouts, isNotEmpty);
      expect(d.progress.state.logs, isEmpty);
    },
  );
}
