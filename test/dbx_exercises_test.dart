import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/data/equipment/equipment_matcher.dart';
import 'package:gymflow/state/app_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'exercícios só com GIF entram na base, todos com aparelho e GIF próprio',
    () async {
      SharedPreferences.setMockInitialValues({});
      final d = await AppDependencies.create();
      final extra = d.catalog.state.exercises
          .where((e) => e.id.startsWith('dbx-'))
          .toList();
      expect(extra.length, greaterThan(500));
      for (final e in extra) {
        expect(itemForExercise(e), isNotNull, reason: '${e.name} sem aparelho');
        expect(d.gifs.gifFor(e), isNotNull, reason: '${e.name} sem GIF');
      }
    },
  );

  test(
    'a geração usa os exercícios simples (peso corporal) vindos do GIF',
    () async {
      SharedPreferences.setMockInitialValues({});
      final d = await AppDependencies.create();
      d.equipment.setAll({
        'bw_legs',
        'bw_core',
        'bw_chest',
        'bw_back',
        'bw_arms',
      });
      d.equipment.save();
      d.planner.setDays({1});
      d.planner.setFocus(1, 'legs');
      final seen = <String>{};
      for (var i = 0; i < 8; i++) {
        await d.planner.generateDay(1);
        for (final it in d.planner.state.drafts[1]!.workout.items) {
          seen.add(it.exerciseId);
        }
      }
      expect(seen.any((id) => id.startsWith('dbx-')), isTrue, reason: '$seen');
    },
  );

  test(
    'cardio só é o que é cardio (esteira, bike...), não carregadas nem abdominais',
    () async {
      SharedPreferences.setMockInitialValues({});
      final d = await AppDependencies.create();
      final cardio = d.catalog.state.exercises
          .where((e) => e.id.startsWith('dbx-') && e.isCardio)
          .map((e) => e.name.toLowerCase())
          .toList();
      for (final n in cardio) {
        expect(
          n.contains('crunch') || n.contains('farmer') || n.contains('lunge'),
          isFalse,
          reason: n,
        );
      }
      final farmers = d.catalog.state.exercises.where(
        (e) => e.name.toLowerCase().replaceAll("'", '') == 'farmers walk',
      );
      expect(farmers, isNotEmpty);
      expect(farmers.every((e) => !e.isCardio), isTrue);
    },
  );
}
