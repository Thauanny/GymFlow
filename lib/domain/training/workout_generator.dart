import '../../models/day_focus.dart';
import '../../models/exercise.dart';
import '../../models/labels.dart';
import '../../models/plan_item.dart';
import '../../models/workout.dart';
import 'day_template.dart';
import 'exercise_filter.dart';
import 'exercise_scorer.dart';
import 'prescription.dart';
import 'progression.dart';
import 'stable_hash.dart';
import 'training_profile.dart';

/// Pedido de geração de um dia de treino.
class GenerationRequest {
  final TrainingProfile profile;
  final DayFocus focus;
  final int weekday;
  final List<Exercise>
  pool; // exercícios possíveis com o equipamento do usuário
  final Set<String> emphasis;
  final Set<String> avoidIds; // já usados em outros dias da semana
  final Map<String, double> relevance; // 0..1, vindo do texto do objetivo
  final int seed;
  final double? Function(String exerciseId) lastLoad;
  final bool Function(Exercise) hasGif;

  const GenerationRequest({
    required this.profile,
    required this.focus,
    required this.weekday,
    required this.pool,
    required this.hasGif,
    this.emphasis = const {},
    this.avoidIds = const {},
    this.relevance = const {},
    this.seed = 0,
    this.lastLoad = _noLoad,
  });
}

double? _noLoad(String _) => null;

/// Treino gerado + o motivo de cada escolha.
class GeneratedDay {
  final Workout workout;
  final Map<String, String> reasons;
  const GeneratedDay(this.workout, this.reasons);
}

/// Gera um dia de treino a partir de regras (modelo do dia, vagas, pontuação).
class WorkoutGenerator {
  GeneratedDay generate(GenerationRequest r) {
    final eligible = r.pool.where((e) => isEligible(e, r.profile)).toList();
    final items = <PlanItem>[];
    final reasons = <String, String>{};

    if (r.focus.isCardio) {
      _addCardio(r, eligible, items, reasons, _cardioCount(r.profile.minutes));
    } else {
      _addStrength(r, eligible, items, reasons);
      if (r.profile.goal == TrainingGoal.fatLoss) {
        _addCardio(r, eligible, items, reasons, 1, finisher: true);
      }
    }
    final workout = Workout(
      '${DateTime.now().microsecondsSinceEpoch}-${r.weekday}',
      '${r.focus.label} - ${weekdayNames[r.weekday - 1]}',
      items,
      day: r.focus.id,
      weekday: r.weekday,
    );
    return GeneratedDay(workout, reasons);
  }

  int _cardioCount(int minutes) => (minutes ~/ 25).clamp(1, 3);

  void _addStrength(
    GenerationRequest r,
    List<Exercise> eligible,
    List<PlanItem> items,
    Map<String, String> reasons,
  ) {
    final pool = eligible.where((e) => !e.isCardio).toList();
    final target = exerciseCountFor(r.profile.minutes);
    final chosen = <Exercise>[];
    final roles = <String, SlotRole>{};

    for (final slot in buildSlots(r.focus, r.emphasis)) {
      if (chosen.length >= target) break;
      final e = _pick(r, pool, slot, chosen);
      if (e == null) continue;
      chosen.add(e);
      roles[e.id] = slot.role;
      reasons[e.id] = _reason(e, slot);
    }
    // Compostos primeiro (mantém a ordem de prioridade dentro de cada grupo).
    chosen.sort((a, b) {
      final ra = roles[a.id] == SlotRole.compound ? 0 : 1;
      final rb = roles[b.id] == SlotRole.compound ? 0 : 1;
      return ra - rb;
    });
    for (final e in chosen) {
      final p = prescribe(r.profile.goal, roles[e.id]!, r.profile.level);
      final last = r.lastLoad(e.id);
      items.add(
        PlanItem(
          e.id,
          p.sets,
          p.reps,
          restSec: p.restSec,
          kg: last == null ? null : nextLoad(last),
        ),
      );
    }
  }

  Exercise? _pick(
    GenerationRequest r,
    List<Exercise> pool,
    Slot slot,
    List<Exercise> chosen,
  ) {
    final taken = chosen.map((e) => e.id).toSet();
    var candidates = pool
        .where((e) => !taken.contains(e.id) && e.primary.contains(slot.muscle))
        .toList();
    if (candidates.isEmpty) {
      candidates = pool
          .where(
            (e) => !taken.contains(e.id) && e.secondary.contains(slot.muscle),
          )
          .toList();
    }
    if (candidates.isEmpty) return null;
    final ctx = ScoreContext(
      profile: r.profile,
      slot: slot,
      chosen: chosen,
      avoidIds: r.avoidIds,
      relevance: r.relevance,
      seed: r.seed,
      hasGif: r.hasGif,
    );
    Exercise? best;
    var bestScore = double.negativeInfinity;
    for (final e in candidates) {
      final s = scoreExercise(e, ctx);
      if (s > bestScore) {
        bestScore = s;
        best = e;
      }
    }
    return best;
  }

  void _addCardio(
    GenerationRequest r,
    List<Exercise> eligible,
    List<PlanItem> items,
    Map<String, String> reasons,
    int count, {
    bool finisher = false,
  }) {
    var pool = eligible.where((e) => e.isCardio).toList();
    if (pool.isEmpty) {
      pool = eligible.where((e) => e.category == 'plyometrics').toList();
    }
    if (pool.isEmpty) return;
    pool.sort((a, b) {
      double s(Exercise e) =>
          (r.hasGif(e) ? 1 : 0) +
          (r.avoidIds.contains(e.id) ? -1 : 0) +
          ((stableHash(e.id) ^ r.seed) % 100) / 100;
      return s(b).compareTo(s(a));
    });
    final minutes = finisher ? 15 : (r.profile.minutes / count).round();
    for (final e in pool.take(count)) {
      items.add(PlanItem(e.id, 1, minutes, restSec: 0));
      reasons[e.id] = finisher
          ? 'Finalizador de cardio para aumentar o gasto calórico'
          : 'Cardio para condicionamento';
    }
  }

  String _reason(Exercise e, Slot slot) {
    final kind = slot.role == SlotRole.compound ? 'Composto' : 'Isolador';
    return '$kind para ${muscleLabel(slot.muscle)}';
  }
}
