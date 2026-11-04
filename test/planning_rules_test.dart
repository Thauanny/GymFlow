import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/ai/goal_text.dart';
import 'package:gymflow/data/equipment/equipment_matcher.dart';
import 'package:gymflow/domain/training/progression.dart';
import 'package:gymflow/domain/training/recovery.dart';
import 'package:gymflow/domain/training/split_planner.dart';
import 'package:gymflow/domain/training/substitutes.dart';
import 'package:gymflow/domain/training/training_profile.dart';
import 'package:gymflow/domain/training/weekly_volume.dart';
import 'package:gymflow/models/day_focus.dart';
import 'package:gymflow/models/plan_item.dart';
import 'package:gymflow/models/workout.dart';

import 'support/exercise_fixtures.dart';

void main() {
  group('divisão da semana', () {
    test(
      '3 dias = superior/pernas/corpo inteiro; iniciante = corpo inteiro',
      () {
        expect(
          suggestSplit([1, 3, 5], const TrainingProfile()).values.toList(),
          ['upper', 'legs', 'full'],
        );
        expect(
          suggestSplit([
            1,
            3,
            5,
          ], const TrainingProfile(level: 'beginner')).values.toList(),
          ['full', 'full', 'full'],
        );
      },
    );

    test('4 dias = ABCD (peito, costas, pernas, ombros) na ordem dos dias', () {
      final split = suggestSplit([5, 1, 3, 2], const TrainingProfile());
      expect(split.keys.toList(), [1, 2, 3, 5]);
      expect(split.values.toList(), [
        'chest_triceps',
        'back_biceps',
        'legs',
        'shoulders_abs',
      ]);
    });

    test('todos os tamanhos de 1 a 7 dias funcionam', () {
      for (var n = 1; n <= 7; n++) {
        final split = suggestSplit(
          List.generate(n, (i) => i + 1),
          const TrainingProfile(),
        );
        expect(split.length, n);
        expect(split.values.every(dayFocuses.containsKey), isTrue);
      }
    });
  });

  test('avisa quando o mesmo grupo treina em dias seguidos', () {
    expect(recoveryWarnings({1: 'legs', 2: 'legs'}), isNotEmpty);
    expect(recoveryWarnings({1: 'chest_triceps', 2: 'legs'}), isEmpty);
    expect(recoveryWarnings({1: 'upper', 3: 'upper'}), isEmpty);
  });

  test('foco antigo (upper1, mixed) é convertido', () {
    expect(focusById('upper1').id, 'upper');
    expect(focusById('mixed').id, 'full');
    expect(focusById('push').id, 'chest_triceps');
    expect(focusById('pull').id, 'back_biceps');
    expect(focusById('lower').id, 'legs');
    expect(focusById('qualquer').id, 'full');
  });

  test('progressão de carga aumenta de forma realista', () {
    expect(nextLoad(8), 9);
    expect(nextLoad(20), 22);
    expect(nextLoad(60), 62.5);
  });

  test('texto do objetivo vira músculos em destaque', () {
    expect(musclesFromText('quero fortalecer glúteos e costas'), {
      'glutes',
      'lats',
      'middle back',
    });
    expect(musclesFromText('definir o abdômen'), {'abdominals'});
    expect(translateGoal('emagrecer pernas'), contains('cardio'));
  });

  test('perfil é salvo e restaurado', () {
    final p = const TrainingProfile(
      goal: TrainingGoal.strength,
      level: 'expert',
      minutes: 45,
      goalText: 'x',
    );
    final back = TrainingProfile.fromJson(p.toJson());
    expect(back.goal, TrainingGoal.strength);
    expect(back.level, 'expert');
    expect(back.minutes, 45);
  });

  test('treino antigo salvo ainda carrega', () {
    final w = Workout.fromJson({
      'id': '1',
      'name': 'Antigo',
      'wd': 2,
      'day': 'upper1',
      'items': [
        {'e': 'abc', 's': 3, 'r': 10, 'd': true},
      ],
    });
    expect(w.day, 'upper');
    expect(w.items.single.restSec, 60);
    expect(w.items.single.done, isTrue);
  });

  test('substitutos mantêm o músculo e não repetem exercícios usados', () {
    final pool = poolFor({'machine', 'cable', 'barbell', 'dumbbell'});
    final current = pool.firstWhere(
      (e) => e.mainMuscle == 'chest' && e.isCompound,
    );
    final options = suggestSubstitutes(
      current: current,
      pool: pool,
      exclude: {current.id},
      profile: const TrainingProfile(),
    );
    expect(options, isNotEmpty);
    for (final e in options) {
      expect(e.mainMuscle, 'chest');
      expect(e.id, isNot(current.id));
    }
  });

  test('substitutos variam o aparelho (não são só variações do mesmo)', () {
    final pool = poolFor({
      'machine',
      'cable',
      'barbell',
      'dumbbell',
      'body only',
    });
    final current = pool.firstWhere(
      (e) =>
          e.mainMuscle == 'lats' && e.name.toLowerCase().contains('pulldown'),
    );
    final options = suggestSubstitutes(
      current: current,
      pool: pool,
      exclude: {current.id},
      profile: const TrainingProfile(),
    );
    final items = options.map((e) => itemForExercise(e)?.id).toSet();
    expect(options.length, greaterThanOrEqualTo(4));
    expect(
      items.length,
      greaterThanOrEqualTo(3),
      reason: 'aparelhos diferentes',
    );
  });

  test('volume semanal soma séries (secundário vale meia série)', () {
    final pool = poolFor({'barbell'});
    final bench = pool.firstWhere(
      (e) => e.primary.contains('chest') && e.secondary.contains('triceps'),
    );
    final w = Workout('1', 'T', [PlanItem(bench.id, 4, 8)]);
    final v = weeklyVolume([
      w,
    ], (id) => pool.where((e) => e.id == id).firstOrNull);
    expect(v['chest'], 4);
    expect(v['triceps'], 2);
    expect(volumeLevel(4), VolumeLevel.low);
    expect(volumeLevel(12), VolumeLevel.ok);
    expect(volumeLevel(25), VolumeLevel.high);
  });
}
