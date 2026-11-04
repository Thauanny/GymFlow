import 'dart:math' as math;

import '../../data/translation/pt_names.dart';
import '../../models/exercise.dart';
import '../../models/plan_item.dart';
import '../../models/workout.dart';
import 'day_template.dart';
import 'exercise_filter.dart';
import 'prescription.dart';
import 'progression.dart';
import 'substitutes.dart';
import 'training_profile.dart';

/// Resultado da evolução de um dia: o novo treino e o que mudou em cada item.
class DayEvolution {
  final Workout workout;
  final Map<String, String> reasons;
  final int loadUps, swaps, added;
  const DayEvolution(
    this.workout,
    this.reasons, {
    this.loadUps = 0,
    this.swaps = 0,
    this.added = 0,
  });
}

/// Gera a próxima versão de um treino já feito (progressão):
/// - carga: sobe a partir da última usada (sem carga: mais repetições);
/// - exercício: mantém os 2 compostos-base e troca o resto por variações;
/// - volume e tempo: +1 série em ciclos alternados, descanso menor,
///   cardio mais longo e um exercício extra quando o tempo aumenta;
/// - dificuldade: o [profile] recebido já traz o nível/tempo da evolução.
class PlanEvolver {
  DayEvolution evolveDay({
    required Workout current,
    required TrainingProfile profile,
    required int cycle,
    required List<Exercise> pool,
    required Exercise? Function(String id) byId,
    required double? Function(String id) lastLoad,
    required Set<String> usedInPlan,
  }) {
    final used = {...usedInPlan};
    final items = <PlanItem>[];
    final reasons = <String, String>{};
    var loadUps = 0, swaps = 0, anchors = 0;
    final minRest = profile.goal == TrainingGoal.strength ? 90 : 30;

    for (final old in current.items) {
      final e = byId(old.exerciseId);
      if (e == null) {
        items.add(old.copy()..setsDone = 0);
        continue;
      }
      if (e.isCardio) {
        final minutes = math.min(old.reps + 5, 45);
        items.add(PlanItem(e.id, 1, minutes, restSec: 0));
        reasons[e.id] = 'Cardio mais longo: $minutes min';
        used.add(e.id);
        continue;
      }

      final isAnchor = e.isCompound && anchors < 2;
      if (isAnchor) anchors++;
      var target = e;
      String? swapNote;
      if (!isAnchor) {
        final options = suggestSubstitutes(
          current: e,
          pool: pool,
          exclude: used,
          profile: profile,
          max: 1,
        );
        if (options.isNotEmpty) {
          target = options.first;
          swaps++;
          swapNote = 'Variação nova (era ${exerciseNamePt(e.name)})';
        }
      }
      used.add(target.id);

      final role = target.isCompound ? SlotRole.compound : SlotRole.isolation;
      final maxSets = role == SlotRole.compound ? 5 : 4;
      final base = prescribe(profile.goal, role, profile.level);
      final sets = math.max(
        base.sets,
        (old.sets + (cycle.isEven ? 1 : 0)).clamp(2, maxSets),
      );
      final rest = math.max(minRest, old.restSec - 10);

      final lastKg = lastLoad(target.id) ?? (target.id == e.id ? old.kg : null);
      double? kg;
      var reps = old.reps;
      final notes = <String>[?swapNote];
      if (lastKg != null) {
        kg = nextLoad(lastKg);
        loadUps++;
        notes.add('Carga ${_kg(lastKg)} → ${_kg(kg)} kg');
      } else {
        reps = math.min(old.reps + 2, 20);
        if (reps != old.reps) notes.add('Mais repetições ($reps)');
      }
      if (sets > old.sets) notes.add('+1 série');
      if (rest < old.restSec) notes.add('descanso ${rest}s');
      items.add(PlanItem(target.id, sets, reps, restSec: rest, kg: kg));
      reasons[target.id] = notes.isEmpty ? 'Mantido' : notes.join(' · ');
    }

    final added = _addExtra(items, reasons, current, profile, pool, byId, used);
    return DayEvolution(
      Workout(
        '${DateTime.now().microsecondsSinceEpoch}-${current.weekday}',
        current.name,
        items,
        day: current.day,
        weekday: current.weekday,
        stretches: [for (final s in current.stretches) s.copy()],
      ),
      reasons,
      loadUps: loadUps,
      swaps: swaps,
      added: added,
    );
  }

  /// Com mais tempo disponível, acrescenta um isolador no músculo menos treinado.
  int _addExtra(
    List<PlanItem> items,
    Map<String, String> reasons,
    Workout current,
    TrainingProfile profile,
    List<Exercise> pool,
    Exercise? Function(String) byId,
    Set<String> used,
  ) {
    final strength = [
      for (final i in items)
        if (byId(i.exerciseId) case final Exercise e when !e.isCardio) e,
    ];
    if (strength.isEmpty ||
        strength.length >= exerciseCountFor(profile.minutes)) {
      return 0;
    }
    final focusMuscles = current.focus.isFullBody
        ? strength.map((e) => e.mainMuscle).whereType<String>().toSet().toList()
        : current.focus.muscles;
    int count(String m) => strength.where((e) => e.mainMuscle == m).length;
    final muscles = [...focusMuscles]..sort((a, b) => count(a) - count(b));
    for (final m in muscles) {
      final candidates = pool
          .where(
            (e) =>
                e.mainMuscle == m &&
                !e.isCompound &&
                !e.isCardio &&
                !used.contains(e.id) &&
                isEligible(e, profile),
          )
          .toList();
      if (candidates.isEmpty) continue;
      candidates.sort(
        (a, b) => (b.images.isEmpty ? 0 : 1) - (a.images.isEmpty ? 0 : 1),
      );
      final e = candidates.first;
      final p = prescribe(profile.goal, SlotRole.isolation, profile.level);
      final at = items.indexWhere((i) => byId(i.exerciseId)?.isCardio ?? false);
      final item = PlanItem(e.id, p.sets, p.reps, restSec: p.restSec);
      at < 0 ? items.add(item) : items.insert(at, item);
      reasons[e.id] = 'Exercício extra: mais volume para o tempo maior';
      used.add(e.id);
      return 1;
    }
    return 0;
  }

  String _kg(double v) => v == v.roundToDouble() ? '${v.round()}' : '$v';
}
