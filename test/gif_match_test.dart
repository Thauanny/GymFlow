import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/data/gif_catalog.dart';
import 'package:gymflow/models/exercise.dart';

import 'support/exercise_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GifCatalog gifs;
  late Map<String, Exercise> byName;

  setUpAll(() async {
    gifs = GifCatalog();
    await gifs.load();
    byName = {for (final e in loadExercises()) e.name: e};
  });

  String? gif(String name) => gifs.gifFor(byName[name]!);

  test('exercício com GIF de mesmo nome usa esse GIF', () {
    expect(gif('Dumbbell Bicep Curl'), isNotNull);
    expect(gif('Cable Deadlifts'), isNotNull);
    expect(gif('Romanian Deadlift'), isNotNull);
    expect(gif('Chest Stretch on Stability Ball'), isNotNull);
    // "pegada média" é a pegada padrão do supino
    expect(gif('Barbell Bench Press - Medium Grip'), isNotNull);
    expect(gif('Wide-Grip Barbell Bench Press'), isNotNull);
    // plural/ortografia: "Flyes" = "fly"
    expect(gif('Dumbbell Flyes'), isNotNull);
    // equivalências conferidas à mão
    expect(gif('Dumbbell Shoulder Press'), isNotNull);
    expect(gif('One-Arm Dumbbell Row'), isNotNull);
    expect(gif('Leg Press'), isNotNull);
    // o mesmo GIF que o card do aparelho usa (cardio e apóstrofo)
    expect(gif('Bicycling, Stationary'), isNotNull);
    expect(gif('Walking, Treadmill'), isNotNull);
    expect(gif('Power Clean'), isNotNull);
    expect(gif("World's Greatest Stretch"), isNotNull);
  });

  test('sem GIF do mesmo exercício, não usa o de outro (vai para a foto)', () {
    for (final name in [
      'One-Legged Cable Kickback', // não é o coice de tríceps
      'Barbell Curls Lying Against An Incline', // não é a rosca em pé
      'Cable Chest Press',
      'Dip Machine',
      'Lateral Raise - With Bands',
      'Seated Cable Shoulder Press',
      'Standing Military Press',
    ]) {
      expect(gif(name), isNull, reason: name);
    }
  });

  test('o GIF nunca é de outro equipamento', () {
    for (final e in byName.values) {
      final u = gifs.gifFor(e);
      if (u == null) continue;
      // um exercício de peso corporal nunca ganha GIF de barra/halter/cabo
      if (e.equipKey == 'body only') {
        final key = gifs.nameOf(u) ?? '';
        expect(
          RegExp(
            r'^(barbell|dumbbell|cable|kettlebell|band|smith) ',
          ).hasMatch(key),
          isFalse,
          reason: '${e.name} => $key',
        );
      }
    }
  });
}
