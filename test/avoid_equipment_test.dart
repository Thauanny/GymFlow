import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/data/equipment/equipment_catalog.dart';
import 'package:gymflow/data/equipment/equipment_matcher.dart';
import 'package:gymflow/domain/training/dual_cable.dart';
import 'package:gymflow/state/app_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppDependencies> gym() async {
    SharedPreferences.setMockInitialValues({});
    final deps = await AppDependencies.create();
    deps.equipment.setAll({for (final i in equipItems) i.id});
    deps.equipment.save();
    deps.planner.setDays({1, 2, 3, 4, 5});
    return deps;
  }

  Set<String?> usedItems(AppDependencies d) => {
    for (final draft in d.planner.state.drafts.values)
      for (final i in draft.workout.items)
        itemForExercise(d.catalog.byId(i.exerciseId)!)?.id,
  };

  test('polia dupla marcada para evitar não entra em nenhum treino', () async {
    final deps = await gym();
    deps.planner.toggleAvoid('c_cross');
    await deps.planner.generateWeek();
    expect(deps.planner.state.drafts, isNotEmpty);
    expect(usedItems(deps), isNot(contains('c_cross')));
  });

  test(
    '"evitar polia dupla" tira crossover, voador e supino na polia',
    () async {
      final deps = await gym();
      deps.planner.toggleAvoid(dualCableKey);
      // vários dias de peito/ombros para dar chance de aparecerem
      deps.planner.setDays({1, 2, 3, 4, 5, 6});
      await deps.planner.generateWeek();
      final names = {
        for (final draft in deps.planner.state.drafts.values)
          for (final i in draft.workout.items) deps.catalog.byId(i.exerciseId)!,
      };
      expect(names, isNotEmpty);
      expect(names.where(usesDualCable), isEmpty);
      // os demais exercícios de cabo continuam permitidos
      expect(deps.equipment.state.available.where(usesDualCable), isNotEmpty);
    },
  );

  test('evitar todos os cabos remove polias dos treinos', () async {
    final deps = await gym();
    for (final i in equipItems.where((i) => i.dbEquip == 'cable')) {
      deps.planner.toggleAvoid(i.id);
    }
    await deps.planner.generateWeek();
    final kinds = {
      for (final draft in deps.planner.state.drafts.values)
        for (final i in draft.workout.items)
          deps.catalog.byId(i.exerciseId)!.equipKey,
    };
    expect(kinds, isNot(contains('cable')));
  });

  test('a escolha de evitar é lembrada e pode ser desfeita', () async {
    final deps = await gym();
    deps.planner.toggleAvoid('c_cross');
    expect(deps.store.getStringList('avoid_items'), ['c_cross']);
    deps.planner.toggleAvoid('c_cross');
    expect(deps.planner.state.avoidedItems, isEmpty);
  });
}
