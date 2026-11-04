import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/data/equipment/equipment_catalog.dart';
import 'package:gymflow/state/app_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dá para adicionar e tirar exercícios do dia gerado', () async {
    SharedPreferences.setMockInitialValues({});
    final deps = await AppDependencies.create();
    deps.equipment.setAll({for (final i in equipItems) i.id});
    deps.equipment.save();
    deps.planner.setDays({1, 2});
    await deps.planner.generateWeek();

    final draft = deps.planner.state.drafts[1]!;
    final before = draft.workout.items.length;
    final used = draft.workout.items.map((i) => i.exerciseId).toSet();
    final extra = deps.equipment.state.available.firstWhere(
      (e) =>
          !used.contains(e.id) && !e.isCardio && e.mainMuscle == 'abdominals',
    );

    deps.planner.addExercise(1, extra);
    final after = deps.planner.state.drafts[1]!;
    expect(after.workout.items.length, before + 1);
    expect(after.workout.items.last.exerciseId, extra.id);
    expect(after.workout.items.last.sets, greaterThan(0));
    expect(after.reasons[extra.id], 'Adicionado por você');

    deps.planner.addExercise(1, extra); // repetido é ignorado
    expect(deps.planner.state.drafts[1]!.workout.items.length, before + 1);

    deps.planner.removeExercise(1, extra.id);
    expect(deps.planner.state.drafts[1]!.workout.items.length, before);

    // o treino adicionado é salvo junto com o plano
    deps.planner.addExercise(1, extra);
    deps.planner.commit(replaceDays: true);
    final saved = deps.workouts.state.forWeekday(1).single;
    expect(saved.items.any((i) => i.exerciseId == extra.id), isTrue);
  });
}
