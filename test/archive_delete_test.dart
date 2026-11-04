import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/core/theme/app_theme.dart';
import 'package:gymflow/data/equipment/equipment_catalog.dart';
import 'package:gymflow/state/app_dependencies.dart';
import 'package:gymflow/ui/features/workouts/plan_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  /// App com uma semana (seg, qua, sex) salva e trocada: o antigo vai ao histórico.
  Future<AppDependencies> withArchive() async {
    SharedPreferences.setMockInitialValues({});
    final d = await AppDependencies.create();
    d.equipment.setAll({for (final i in equipItems) i.id});
    d.equipment.save();
    d.planner.setDays({1, 3, 5});
    await d.planner.generateWeek();
    d.planner.commit(replaceDays: true);
    await d.planActions.changePlan();
    return d;
  }

  test('apagar um treino do plano antigo mantém os demais', () async {
    final d = await withArchive();
    final plan = d.workouts.state.archive.first;
    expect(plan.workouts, hasLength(3));

    d.workouts.deleteArchivedWorkout(plan.id, plan.workouts.first.id);

    final after = d.workouts.state.archive.first;
    expect(after.id, plan.id);
    expect(after.workouts, hasLength(2));
    expect(
      after.workouts.map((w) => w.id),
      isNot(contains(plan.workouts.first.id)),
    );
  });

  test('apagar o último treino remove o plano do histórico', () async {
    final d = await withArchive();
    final plan = d.workouts.state.archive.first;
    for (final w in plan.workouts) {
      d.workouts.deleteArchivedWorkout(plan.id, w.id);
    }
    expect(d.workouts.state.archive.where((a) => a.id == plan.id), isEmpty);
  });

  testWidgets('segurar o cartão do plano antigo oferece apagar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final d = (await tester.runAsync(withArchive))!;
    final count = d.workouts.state.archive.length;

    await tester.pumpWidget(
      d.provide(
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: const Scaffold(
            body: SingleChildScrollView(child: PlanHistorySection()),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.longPress(find.text(d.workouts.state.archive.first.label));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Excluir do histórico?'), findsOneWidget);

    await tester.tap(find.text('Excluir'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(d.workouts.state.archive, hasLength(count - 1));
  });
}
