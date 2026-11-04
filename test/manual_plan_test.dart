import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/core/theme/app_theme.dart';
import 'package:gymflow/data/equipment/equipment_catalog.dart';
import 'package:gymflow/state/app_dependencies.dart';
import 'package:gymflow/ui/features/planner/planner_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('montar manual: cada dia é um treino separado', (tester) async {
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final d = (await tester.runAsync(() async {
      final d = await AppDependencies.create();
      d.equipment.setAll({for (final i in equipItems) i.id});
      d.equipment.save();
      d.planner.setDays({1, 2});
      return d;
    }))!;

    await tester.pumpWidget(
      d.provide(
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: const PlannerPage(manual: true),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // um treino vazio por dia, cada um com o foco do dia
    expect(d.planner.state.drafts.keys.toSet(), {1, 2});
    expect(d.planner.state.drafts[1]!.workout.weekday, 1);
    expect(d.planner.state.drafts[2]!.workout.weekday, 2);
    expect(d.planner.hasContent, isFalse);

    // adiciona itens diferentes em cada dia
    final pool = d.equipment.state.available.where((e) => !e.isCardio).toList();
    d.planner.addExercise(1, pool.first);
    d.planner.addExercise(2, pool.last);
    d.planner.addStretch(1, d.equipment.stretches.first);
    expect(d.planner.hasContent, isTrue);

    // trocar o dia de foco não apaga o que já foi adicionado
    d.planner.ensureManualDrafts();
    expect(d.planner.state.drafts[1]!.workout.items, hasLength(1));

    final n = d.planner.commit(replaceDays: false);
    expect(n, 2);
    final saved = d.workouts.state.workouts;
    final seg = saved.firstWhere((w) => w.weekday == 1);
    final ter = saved.firstWhere((w) => w.weekday == 2);
    expect(seg.items.single.exerciseId, pool.first.id);
    expect(seg.stretches, hasLength(1));
    expect(ter.items.single.exerciseId, pool.last.id);
    expect(ter.stretches, isEmpty);
    expect(seg.id, isNot(ter.id));
  });

  test('dia sem nada adicionado não vira treino', () async {
    SharedPreferences.setMockInitialValues({});
    final d = await AppDependencies.create();
    d.equipment.setAll({for (final i in equipItems) i.id});
    d.equipment.save();
    d.planner.setDays({1, 3});
    d.planner.ensureManualDrafts();
    d.planner.addExercise(
      1,
      d.equipment.state.available.firstWhere((e) => !e.isCardio),
    );
    // o dia 3 continua vazio: não pode salvar o plano
    expect(d.planner.emptyDays, [3]);
    d.planner.removeDraft(3);
    expect(d.planner.emptyDays, isEmpty);
    expect(d.planner.commit(replaceDays: false), 1);
    expect(d.workouts.state.workouts.single.weekday, 1);
  });
}
