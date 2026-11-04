import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/domain/training/stretch_planner.dart';
import 'package:gymflow/domain/training/training_profile.dart';
import 'package:gymflow/domain/training/workout_generator.dart';
import 'package:gymflow/models/day_focus.dart';
import 'package:gymflow/models/exercise.dart';

Exercise _s(String id, String muscle) => Exercise.fromJson({
  'id': id,
  'name': id,
  'category': 'stretching',
  'primaryMuscles': [muscle],
  'images': ['$id/0.jpg'],
});

void main() {
  final pool = [
    for (final m in ['hamstrings', 'quadriceps', 'calves', 'glutes', 'chest'])
      for (var i = 0; i < 2; i++) _s('$m$i', m),
  ];

  GenerationRequest req(String focus, {TrainingProfile? p}) =>
      GenerationRequest(
        profile: p ?? const TrainingProfile(minutes: 60),
        focus: dayFocuses[focus]!,
        weekday: 1,
        pool: const [],
        stretchPool: pool,
        hasGif: (_) => false,
      );

  test('alongamentos são dos músculos do dia, sem repetir', () {
    final list = planStretches(req('legs'), {});
    final ids = list.map((i) => i.exerciseId).toList();
    expect(ids.toSet().length, ids.length);
    expect(ids.length, 4); // um por músculo do dia que tem alongamento
    expect(ids.any((i) => i.startsWith('chest')), isFalse);
    expect(list.first.reps, stretchHoldSec);
  });

  test('dia de peito só alonga o que existe para peito', () {
    final ids = planStretches(
      req('chest_triceps'),
      {},
    ).map((i) => i.exerciseId).toList();
    expect(ids, everyElement(startsWith('chest')));
  });

  test('não repete a mesma imagem nem o mesmo músculo à toa', () {
    final r = GenerationRequest(
      profile: const TrainingProfile(minutes: 90),
      focus: dayFocuses['chest_triceps']!,
      weekday: 1,
      pool: const [],
      stretchPool: pool,
      gifUrl: (e) =>
          'gif-${e.primary.first}', // todos do músculo = mesma imagem
      hasGif: (_) => true,
    );
    final ids = planStretches(r, {}).map((i) => i.exerciseId).toList();
    final muscles = ids.map((i) => i.replaceAll(RegExp(r'\d'), '')).toList();
    expect(muscles.toSet().length, muscles.length);
  });

  test('perfil sem alongamento gera treino sem alongamentos', () {
    final g = WorkoutGenerator().generate(
      req('legs', p: const TrainingProfile(stretching: false)),
    );
    expect(g.workout.stretches, isEmpty);
  });
}
