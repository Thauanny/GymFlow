import '../../models/exercise.dart';
import '../movement_patterns.dart';
import 'exercise_filter.dart';
import 'training_profile.dart';

/// Exercícios que podem trocar [current]: primeiro os do **mesmo movimento**
/// (terra por terra, supino por supino...) em qualquer equipamento que o usuário
/// tem, depois os que trabalham o mesmo músculo. Prioriza equipamentos
/// diferentes do atual, para dar variedade.
List<Exercise> suggestSubstitutes({
  required Exercise current,
  required List<Exercise> pool,
  required Set<String> exclude,
  required TrainingProfile profile,
  int max = 8,
}) {
  final muscle = current.mainMuscle ?? (current.isCardio ? '' : null);
  if (muscle == null) return [];
  final family = movementFamily(current.name);
  final related = relatedMuscles(family, muscle);

  double score(Exercise e) {
    final sameMove = family != null && movementFamily(e.name) == family;
    var s = sameMove ? 10.0 : 0.0;
    if (e.mainMuscle == muscle) s += 4;
    if (e.isCompound == current.isCompound) s += 1;
    if (e.equipKey != current.equipKey) s += 2; // variedade de equipamento
    if (e.images.isNotEmpty) s += .5;
    if (e.level == profile.level) s += .5;
    return s;
  }

  bool fits(Exercise e) {
    // Cardio troca por qualquer outro cardio (esteira, bike...), sem olhar músculo.
    if (current.isCardio) return e.isCardio;
    final m = e.mainMuscle;
    if (m == null) return false;
    final sameMove = family != null && movementFamily(e.name) == family;
    // mesmo movimento: músculo "parente"; senão, exatamente o mesmo músculo
    return sameMove ? related.contains(m) : m == muscle;
  }

  final ranked =
      pool
          .where(
            (e) =>
                e.id != current.id &&
                !exclude.contains(e.id) &&
                e.isCardio == current.isCardio &&
                isEligible(e, profile) &&
                fits(e),
          )
          .toList()
        ..sort((a, b) => score(b).compareTo(score(a)));
  // Mesmo movimento primeiro (variando o equipamento); só depois o mesmo
  // músculo com outro movimento.
  final same = [
    for (final e in ranked)
      if (family != null && movementFamily(e.name) == family) e,
  ];
  final others = [
    for (final e in ranked)
      if (!same.contains(e)) e,
  ];
  final out = _diversify(same, max);
  if (out.length < max) out.addAll(_diversify(others, max - out.length));
  return out;
}

/// Todas as trocas possíveis, sem corte: o mesmo movimento (em qualquer
/// equipamento que o usuário tem) e, à parte, o mesmo músculo com outro
/// movimento. Dentro de cada lista, o equipamento do exercício atual vem
/// primeiro e depois os demais agrupados por equipamento.
class SubstituteOptions {
  final List<Exercise> sameMovement, sameMuscle;
  const SubstituteOptions(this.sameMovement, this.sameMuscle);
  bool get isEmpty => sameMovement.isEmpty && sameMuscle.isEmpty;
}

const _equipOrder = [
  'barbell',
  'dumbbell',
  'machine',
  'cable',
  'e-z curl bar',
  'kettlebells',
  'bands',
  'exercise ball',
  'medicine ball',
  'body only',
  'other',
  'foam roll',
];

SubstituteOptions substituteOptions({
  required Exercise current,
  required List<Exercise> pool,
  required Set<String> exclude,
  required TrainingProfile profile,
}) {
  final muscle = current.mainMuscle ?? (current.isCardio ? '' : null);
  if (muscle == null) return const SubstituteOptions([], []);
  final family = movementFamily(current.name);
  final related = relatedMuscles(family, muscle);

  bool sameMove(Exercise e) =>
      family != null && movementFamily(e.name) == family;
  bool fits(Exercise e) {
    if (current.isCardio) return e.isCardio;
    final m = e.mainMuscle;
    if (m == null) return false;
    return sameMove(e) ? related.contains(m) : m == muscle;
  }

  int rank(Exercise e) {
    if (e.equipKey == current.equipKey) return -1;
    final i = _equipOrder.indexOf(e.equipKey);
    return i < 0 ? _equipOrder.length : i;
  }

  double score(Exercise e) =>
      (e.isCompound == current.isCompound ? 1 : 0) +
      (e.images.isNotEmpty ? .5 : 0) +
      (e.level == profile.level ? .5 : 0);

  final ranked = [
    for (final e in pool)
      if (e.id != current.id &&
          !exclude.contains(e.id) &&
          e.isCardio == current.isCardio &&
          isEligible(e, profile) &&
          fits(e))
        e,
  ];
  int order(Exercise a, Exercise b) {
    final r = rank(a) - rank(b);
    if (r != 0) return r;
    final s = score(b).compareTo(score(a));
    return s != 0 ? s : a.name.compareTo(b.name);
  }

  final same = ranked.where(sameMove).toList()..sort(order);
  final others = ranked.where((e) => !sameMove(e)).toList()..sort(order);
  return SubstituteOptions(same, others);
}

/// Alterna entre aparelhos: o melhor de cada aparelho primeiro, depois o
/// segundo melhor de cada um... Evita sugerir 6 variações do mesmo aparelho.
List<Exercise> _diversify(List<Exercise> ranked, int max) {
  final byItem = <String, List<Exercise>>{};
  for (final e in ranked) {
    byItem.putIfAbsent(e.equipKey, () => []).add(e);
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
