import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/data/translation/pt_exercise_names.dart';
import 'package:gymflow/data/translation/pt_names.dart';

import 'support/exercise_fixtures.dart';

void main() {
  final all = loadExercises();

  test('todos os exercícios da base têm tradução curada', () {
    final missing = all.where((e) => !ptExerciseNames.containsKey(e.name));
    expect(missing.map((e) => e.name).toList(), isEmpty);
  });

  test('nenhuma tradução vazia e exerciseNamePt usa a curada', () {
    for (final e in all) {
      expect(ptExerciseNames[e.name], isNotEmpty);
      expect(exerciseNamePt(e.name), ptExerciseNames[e.name]);
    }
  });

  test('exemplos que antes saíam errados', () {
    expect(
      exerciseNamePt('Deficit Deadlift'),
      'Levantamento terra com déficit',
    );
    expect(exerciseNamePt('Rack Pulls'), 'Rack pull (terra no rack)');
    expect(
      exerciseNamePt('Stiff Leg Barbell Good Morning'),
      'Bom dia com barra e pernas estendidas',
    );
    expect(exerciseNamePt('Iron Cross'), 'Cruz de ferro (com halteres)');
  });
}
