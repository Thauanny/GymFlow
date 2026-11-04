import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/domain/training/recovery.dart';
import 'package:gymflow/domain/training/split_planner.dart';
import 'package:gymflow/domain/training/training_profile.dart';

void main() {
  const levels = ['beginner', 'intermediate', 'expert'];

  test('a divisão sugerida nunca repete músculos em dias seguidos', () {
    // todas as combinações de dias, em todos os níveis
    for (var mask = 1; mask < 128; mask++) {
      final days = [
        for (var d = 1; d <= 7; d++)
          if (mask & (1 << (d - 1)) != 0) d,
      ];
      for (final level in levels) {
        final split = suggestSplit(days, TrainingProfile(level: level));
        expect(
          recoveryWarnings(split),
          isEmpty,
          reason: '$days ($level): $split',
        );
        expect(split.keys.toSet(), days.toSet());
      }
    }
  });

  test('dias que repetem músculo viram cardio (descanso do músculo)', () {
    final split = suggestSplit([1, 2, 3], const TrainingProfile());
    expect(split[1], 'upper');
    expect(split[2], 'legs');
    // upper, legs, full: o terceiro repetiria as pernas, então vira cardio
    expect(split[3], 'cardio');
    expect(recoveryWarnings(split), isEmpty);
    final beginner = suggestSplit([
      1,
      2,
    ], const TrainingProfile(level: 'beginner'));
    expect(beginner[1], 'full');
    expect(beginner[2], 'cardio');
  });

  test('dias espaçados mantêm o treino original', () {
    final split = suggestSplit([1, 3, 5], const TrainingProfile());
    expect(split.values, ['upper', 'legs', 'full']);
  });
}
