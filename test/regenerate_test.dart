import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/data/equipment/equipment_catalog.dart';
import 'package:gymflow/state/app_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('"gerar de novo" produz um treino diferente', () async {
    SharedPreferences.setMockInitialValues({});
    final deps = await AppDependencies.create();
    deps.equipment.setAll({for (final i in equipItems) i.id});
    deps.equipment.save();
    deps.planner.setDays({1, 3, 5});

    Map<int, Set<String>> snapshot() => {
      for (final e in deps.planner.state.drafts.entries)
        e.key: e.value.workout.items.map((i) => i.exerciseId).toSet(),
    };

    await deps.planner.generateWeek();
    final first = snapshot();
    expect(deps.planner.state.busy, isFalse);

    await deps.planner.generateWeek();
    final second = snapshot();
    expect(deps.planner.state.busy, isFalse);

    for (final day in first.keys) {
      final same = first[day]!.intersection(second[day]!).length;
      final ratio = same / first[day]!.length;
      // ignore: avoid_print
      print('dia $day: ${(ratio * 100).round()}% igual');
      expect(ratio, lessThan(.6), reason: 'dia $day quase não mudou');
    }
  });
}
