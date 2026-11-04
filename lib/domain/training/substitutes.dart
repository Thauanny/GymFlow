import '../../data/equipment/equipment_matcher.dart';
import '../../models/exercise.dart';
import '../movement_patterns.dart';
import 'exercise_filter.dart';
import 'training_profile.dart';

/// Exercícios que podem trocar [current] mantendo músculo e tipo de movimento.
/// Prioriza outro aparelho (variedade) e o mesmo padrão de movimento.
List<Exercise> suggestSubstitutes({
  required Exercise current,
  required List<Exercise> pool,
  required Set<String> exclude,
  required TrainingProfile profile,
  int max = 6,
}) {
  final muscle = current.mainMuscle;
  if (muscle == null) return [];
  final move = movementOf(current.name);
  final item = itemForExercise(current);

  double score(Exercise e) {
    var s = 0.0;
    if (e.isCompound == current.isCompound) s += 2;
    if (move != null && movementOf(e.name) == move) s += 2;
    if (itemForExercise(e)?.id != item?.id) s += 1;
    if (e.images.isNotEmpty) s += .5;
    if (e.level == profile.level) s += .5;
    return s;
  }

  final ranked =
      pool
          .where(
            (e) =>
                e.id != current.id &&
                !exclude.contains(e.id) &&
                e.mainMuscle == muscle &&
                e.isCardio == current.isCardio &&
                isEligible(e, profile),
          )
          .toList()
        ..sort((a, b) => score(b).compareTo(score(a)));
  return _diversify(ranked, max);
}

/// Alterna entre aparelhos: o melhor de cada aparelho primeiro, depois o
/// segundo melhor de cada um... Evita sugerir 6 variações do mesmo aparelho.
List<Exercise> _diversify(List<Exercise> ranked, int max) {
  final byItem = <String?, List<Exercise>>{};
  for (final e in ranked) {
    byItem.putIfAbsent(itemForExercise(e)?.id, () => []).add(e);
  }
  final groups = byItem.values.toList(); // já na ordem do melhor de cada grupo
  final out = <Exercise>[];
  for (var round = 0; out.length < max; round++) {
    final before = out.length;
    for (final g in groups) {
      if (round < g.length && out.length < max) out.add(g[round]);
    }
    if (out.length == before) break; // acabaram os candidatos
  }
  return out;
}
