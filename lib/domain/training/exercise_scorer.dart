import '../../data/equipment/equipment_matcher.dart';
import '../../models/exercise.dart';
import '../movement_patterns.dart';
import 'day_template.dart';
import 'stable_hash.dart';
import 'training_profile.dart';

/// Tudo que o pontuador precisa saber sobre o treino em construção.
class ScoreContext {
  final TrainingProfile profile;
  final Slot slot;
  final List<Exercise> chosen;
  final Set<String> avoidIds;
  final Map<String, double> relevance;
  final int seed;
  final bool Function(Exercise) hasGif;

  const ScoreContext({
    required this.profile,
    required this.slot,
    required this.chosen,
    required this.avoidIds,
    required this.relevance,
    required this.seed,
    required this.hasGif,
  });
}

/// Nota de um exercício para uma vaga: maior = melhor escolha.
double scoreExercise(Exercise e, ScoreContext c) {
  var s = 0.0;
  s += _roleScore(e, c.slot.role);
  s += _levelScore(e, c.profile.level);
  s += _equipmentScore(e, c);
  if (c.hasGif(e)) s += .8;
  if (e.images.isNotEmpty) s += .5;
  if (!e.primary.contains(c.slot.muscle)) s -= 2; // só músculo secundário
  s += _varietyPenalty(e, c);
  s += 2 * (c.relevance[e.id] ?? 0);
  s +=
      (stableHash(e.id) ^ c.seed) %
      1000 /
      1000 *
      1.6; // variação: "gerar de novo" muda o treino
  return s;
}

double _roleScore(Exercise e, SlotRole role) {
  final wantsCompound = role == SlotRole.compound;
  return e.isCompound == wantsCompound ? 3 : -2;
}

double _levelScore(Exercise e, String level) {
  final diff = levelRank(level) - levelRank(e.level);
  return diff == 0 ? 1.5 : .5;
}

double _equipmentScore(Exercise e, ScoreContext c) {
  final p = c.profile;
  final compound = c.slot.role == SlotRole.compound;
  var s = 0.0;
  switch (e.equipKey) {
    case 'barbell':
      if (compound && p.level != 'beginner') s += 1;
      if (compound && p.goal == TrainingGoal.strength) s += 1;
    case 'machine' || 'cable':
      if (p.level == 'beginner') s += 1;
    case 'dumbbell':
      s += .5;
    case 'body only' || 'kettlebells':
      if (p.goal == TrainingGoal.fatLoss) s += .5;
  }
  if (e.category == 'powerlifting' && p.goal == TrainingGoal.strength) s += .5;
  if (e.category == 'plyometrics') s += .3;
  return s;
}

double _varietyPenalty(Exercise e, ScoreContext c) {
  var s = 0.0;
  if (c.avoidIds.contains(e.id)) s -= 3;
  final item = itemForExercise(e);
  final move = movementOf(e.name);
  for (final o in c.chosen) {
    if (item != null && itemForExercise(o)?.id == item.id) s -= 1.5;
    if (move != null &&
        movementOf(o.name) == move &&
        o.mainMuscle == e.mainMuscle) {
      s -= 2;
    }
  }
  return s;
}
