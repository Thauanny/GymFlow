import '../../models/exercise.dart';
import '../../models/labels.dart';
import '../../models/plan_item.dart';
import 'stable_hash.dart';
import 'workout_generator.dart';

/// Músculo do treino → músculos que o alongamento deve cobrir.
const _stretchTargets = <String, List<String>>{
  'traps': ['neck', 'shoulders'],
  'lower back': ['lower back'],
};

/// Músculos que ajudam a completar o alongamento de dias com poucos músculos.
const _related = <String, String>{
  'chest': 'shoulders',
  'triceps': 'shoulders',
  'biceps': 'forearms',
  'abdominals': 'lower back',
  'lats': 'shoulders',
};

/// Dia de cardio: alongar o que mais trabalha (pernas).
const _cardioMuscles = ['calves', 'quadriceps', 'hamstrings', 'glutes'];

const stretchSets = 2;
const stretchHoldSec = 30;

/// Quantos alongamentos cabem na sessão, conforme o tempo do treino.
int stretchCountFor(int minutes) => minutes <= 30
    ? 3
    : minutes <= 45
    ? 4
    : minutes <= 60
    ? 5
    : 6;

/// Escolhe alongamentos específicos para os músculos do dia (os destacados
/// primeiro). Um por músculo; se sobrar espaço, uma segunda rodada.
List<PlanItem> planStretches(GenerationRequest r, Map<String, String> reasons) {
  if (r.stretchPool.isEmpty) return [];
  final muscles = <String>[];
  void add(String m) {
    for (final t in _stretchTargets[m] ?? [m]) {
      if (!muscles.contains(t)) muscles.add(t);
    }
  }

  final base = r.focus.isCardio ? _cardioMuscles : r.focus.muscles;
  for (final m in base) {
    if (r.emphasis.contains(m)) add(m);
  }
  for (final m in base) {
    add(m);
  }

  for (final m in [...muscles]) {
    final rel = _related[m];
    if (rel != null && muscles.length < 4 && !muscles.contains(rel)) {
      muscles.add(rel);
    }
  }

  final target = stretchCountFor(r.profile.minutes);
  final chosen = <Exercise>[];
  final usedGifs = <String>{};
  double score(Exercise e) =>
      (r.hasGif(e) ? 1 : (e.images.isNotEmpty ? .5 : 0)) +
      (r.avoidIds.contains(e.id) ? -1 : 0) +
      ((stableHash(e.id) ^ r.seed) % 100) / 100;

  // Um por músculo. Uma segunda rodada só se a ficha ficar muito curta, e
  // nunca com a mesma imagem de um alongamento já escolhido.
  for (var round = 0; round < 2 && chosen.length < target; round++) {
    if (round == 1 && chosen.length >= 3) break;
    for (final m in muscles) {
      if (chosen.length >= target) break;
      final c =
          r.stretchPool
              .where(
                (e) =>
                    e.primary.contains(m) &&
                    !chosen.contains(e) &&
                    !usedGifs.contains(r.gifUrl(e)),
              )
              .toList()
            ..sort((a, b) => score(b).compareTo(score(a)));
      if (c.isEmpty) continue;
      chosen.add(c.first);
      final g = r.gifUrl(c.first);
      if (g != null) usedGifs.add(g);
      reasons[c.first.id] = 'Alongamento: ${muscleLabel(m)}';
    }
  }
  return [
    for (final e in chosen)
      PlanItem(e.id, stretchSets, stretchHoldSec, restSec: 0),
  ];
}
