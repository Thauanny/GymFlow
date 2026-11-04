import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/domain/training/prescription.dart';
import 'package:gymflow/domain/training/training_profile.dart';
import 'package:gymflow/domain/training/workout_generator.dart';
import 'package:gymflow/models/day_focus.dart';
import 'package:gymflow/models/exercise.dart';

import 'support/exercise_fixtures.dart';

GenerationRequest request(
  List<Exercise> pool,
  String focus, {
  TrainingProfile profile = const TrainingProfile(),
  Set<String> emphasis = const {},
  Set<String> avoid = const {},
  int seed = 1,
}) => GenerationRequest(
  profile: profile,
  focus: focusById(focus),
  weekday: 1,
  pool: pool,
  emphasis: emphasis,
  avoidIds: avoid,
  seed: seed,
  hasGif: (_) => false,
);

void main() {
  final gym = poolFor({'machine', 'cable', 'barbell', 'dumbbell', 'body only'});
  final byId = {for (final e in gym) e.id: e};
  final generator = WorkoutGenerator();

  test(
    'a base de exercícios carrega',
    () => expect(gym.length, greaterThan(300)),
  );

  for (final focus in [
    'chest_triceps',
    'back_biceps',
    'shoulders_abs',
    'legs',
    'upper',
    'full',
  ]) {
    test('dia "$focus": músculos corretos, sem repetir, tamanho esperado', () {
      final day = generator.generate(request(gym, focus));
      final items = day.workout.items;
      final ids = items.map((i) => i.exerciseId).toList();
      expect(ids.toSet().length, ids.length, reason: 'sem repetições');
      expect(items.length, inInclusiveRange(4, exerciseCountFor(60)));
      final muscles = focusById(focus).muscles;
      for (final i in items) {
        final e = byId[i.exerciseId]!;
        expect(
          e.primary.any(muscles.contains) || e.secondary.any(muscles.contains),
          isTrue,
          reason: '${e.name} não pertence ao foco $focus',
        );
        expect(day.reasons[e.id], isNotNull);
      }
    });
  }

  test('compostos vêm antes de isoladores', () {
    final day = generator.generate(request(gym, 'upper'));
    final flags = [
      for (final i in day.workout.items) byId[i.exerciseId]!.isCompound,
    ];
    final firstIsolation = flags.indexOf(false);
    if (firstIsolation >= 0) {
      expect(flags.skip(firstIsolation).every((c) => !c), isTrue);
    }
  });

  test('iniciante não recebe exercício avançado', () {
    final day = generator.generate(
      request(gym, 'full', profile: const TrainingProfile(level: 'beginner')),
    );
    for (final i in day.workout.items) {
      expect(levelRank(byId[i.exerciseId]!.level), 0);
    }
  });

  test('mais tempo gera mais exercícios', () {
    int count(int min) => generator
        .generate(request(gym, 'full', profile: TrainingProfile(minutes: min)))
        .workout
        .items
        .length;
    expect(count(90), greaterThan(count(30)));
  });

  test('músculo em destaque ganha mais exercícios', () {
    int count(Set<String> emphasis) => generator
        .generate(
          request(
            gym,
            'chest_triceps',
            emphasis: emphasis,
            profile: const TrainingProfile(minutes: 90),
          ),
        )
        .workout
        .items
        .where((i) => byId[i.exerciseId]!.primary.contains('triceps'))
        .length;
    expect(count({'triceps'}), greaterThanOrEqualTo(count({})));
  });

  test('evita repetir exercícios de outros dias', () {
    final a = generator.generate(request(gym, 'upper'));
    final used = a.workout.items.map((i) => i.exerciseId).toSet();
    final b = generator.generate(request(gym, 'upper', avoid: used));
    final overlap = b.workout.items.where((i) => used.contains(i.exerciseId));
    expect(overlap.length, lessThanOrEqualTo(1));
  });

  test('"gerar de novo" (outra seed) varia o treino', () {
    final a = generator.generate(request(gym, 'chest_triceps', seed: 1));
    final b = generator.generate(request(gym, 'chest_triceps', seed: 99999));
    List<String> ids(GeneratedDay d) =>
        d.workout.items.map((i) => i.exerciseId).toList();
    expect(ids(a), isNot(ids(b)));
  });

  test('só halteres ainda gera treino completo', () {
    final dumbbells = poolFor({'dumbbell'});
    final day = generator.generate(request(dumbbells, 'full'));
    expect(day.workout.items.length, greaterThanOrEqualTo(4));
    for (final i in day.workout.items) {
      expect(dumbbells.any((e) => e.id == i.exerciseId), isTrue);
    }
  });

  test('prescrição segue o objetivo', () {
    final strength = generator.generate(
      request(
        gym,
        'chest_triceps',
        profile: const TrainingProfile(goal: TrainingGoal.strength),
      ),
    );
    final endurance = generator.generate(
      request(
        gym,
        'chest_triceps',
        profile: const TrainingProfile(goal: TrainingGoal.endurance),
      ),
    );
    expect(
      strength.workout.items.first.reps,
      lessThan(endurance.workout.items.first.reps),
    );
    expect(
      strength.workout.items.first.restSec,
      greaterThan(endurance.workout.items.first.restSec),
    );
  });

  test('emagrecimento termina com cardio quando há opção', () {
    final all = loadExercises();
    final day = generator.generate(
      request(
        all,
        'full',
        profile: const TrainingProfile(goal: TrainingGoal.fatLoss),
      ),
    );
    final last = day.workout.items.last;
    expect(all.firstWhere((e) => e.id == last.exerciseId).isCardio, isTrue);
  });

  test('dia de cardio só tem cardio', () {
    final all = loadExercises();
    final day = generator.generate(request(all, 'cardio'));
    expect(day.workout.items, isNotEmpty);
    for (final i in day.workout.items) {
      expect(all.firstWhere((e) => e.id == i.exerciseId).isCardio, isTrue);
    }
  });
}
