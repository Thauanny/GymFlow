import '../data/storage/key_value_store.dart';
import '../domain/training/plan_evolver.dart';
import '../domain/training/split_planner.dart';
import '../domain/training/training_profile.dart';
import '../models/day_focus.dart';
import '../models/labels.dart';
import '../models/workout.dart';
import 'catalog_cubit.dart';
import 'planner_cubit.dart';
import 'progress_cubit.dart';
import 'workouts_cubit.dart';

const _cycleKey = 'evolution_cycle';

/// O que uma ação mudou, com o necessário para desfazer.
class PlanChange {
  final List<Workout> removed, added;
  final String? archiveId; // entrada do histórico criada (para desfazer)
  final TrainingProfile? profileBefore; // só quando a evolução muda o perfil
  final int? cycleBefore;
  final String summary;
  const PlanChange({
    required this.removed,
    required this.added,
    required this.summary,
    this.archiveId,
    this.profileBefore,
    this.cycleBefore,
  });
}

/// "Mudar plano" e "Evoluir": trocam os treinos já salvos (só um dia ou a
/// semana toda) sem passar pelo planejador.
class PlanActions {
  final KeyValueStore _store;
  final CatalogCubit _catalog;
  final WorkoutsCubit _workouts;
  final ProgressCubit _progress;
  final PlannerCubit _planner;
  final PlanEvolver _evolver;

  PlanActions(
    this._store,
    this._catalog,
    this._workouts,
    this._progress,
    this._planner,
    this._evolver,
  );

  /// Quantas evoluções da semana inteira já foram feitas.
  int get cycle => int.tryParse(_store.getString(_cycleKey) ?? '') ?? 0;

  /// Dias com treino (ou escolhidos para treinar); só [onlyDay] se informado.
  List<int> _targetDays(int? onlyDay, {required bool needsWorkout}) {
    final ws = _workouts.state;
    final withWorkout = {
      for (final w in ws.workouts)
        if (w.weekday != null) w.weekday!,
    };
    final base = onlyDay != null
        ? {onlyDay}
        : (needsWorkout ? withWorkout : {...ws.trainDays, ...withWorkout});
    return [
      for (final d in base)
        if (!needsWorkout || withWorkout.contains(d)) d,
    ]..sort();
  }

  /// Gera treinos novos com o perfil atual e troca os dos dias escolhidos.
  /// Mantém o foco de cada dia que já tinha treino.
  Future<PlanChange?> changePlan({int? onlyDay}) async {
    final days = _targetDays(onlyDay, needsWorkout: false);
    final pool = _planner.pool;
    if (days.isEmpty || pool.isEmpty) return null;
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final scores = await _planner.relevance(pool);

    final ws = _workouts.state;
    final split = suggestSplit(days, _planner.state.profile);
    final avoid = {
      for (final w in ws.workouts) ...w.items.map((i) => i.exerciseId),
    };
    final seed = DateTime.now().millisecondsSinceEpoch % 100000;
    final removed = [for (final d in days) ...ws.forWeekday(d)];
    final added = <Workout>[];
    for (final d in days) {
      final focusId = ws.forWeekday(d).firstOrNull?.day ?? split[d] ?? 'full';
      final g = _planner.buildDay(
        day: d,
        focus: focusById(focusId),
        avoid: avoid,
        relevance: scores,
        seed: seed + d,
      );
      avoid.addAll(g.workout.items.map((i) => i.exerciseId));
      added.add(g.workout);
    }
    final archiveId = _workouts.apply(
      remove: removed,
      add: added,
      archiveLabel: onlyDay == null
          ? 'Antes de mudar o plano'
          : 'Antes de mudar ${weekdayFull[onlyDay - 1]}',
    );
    return PlanChange(
      removed: removed,
      added: added,
      archiveId: archiveId,
      summary: onlyDay == null
          ? 'Plano da semana trocado'
          : 'Treino de ${weekdayFull[onlyDay - 1]} trocado',
    );
  }

  /// Gera a próxima versão do plano: mais carga, variações de exercício, mais
  /// séries/tempo e, em ciclos alternados, o nível seguinte.
  /// Na semana toda também atualiza nível e tempo do perfil.
  Future<PlanChange?> evolvePlan({int? onlyDay}) async {
    final days = _targetDays(onlyDay, needsWorkout: true);
    final pool = _planner.pool;
    if (days.isEmpty || pool.isEmpty) return null;
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final global = onlyDay == null;
    final profile = _planner.state.profile;
    final c = cycle;
    final nextLevel = global && c.isOdd
        ? _nextLevel(profile.level)
        : profile.level;
    final evolved = global
        ? profile.copyWith(
            level: nextLevel,
            minutes: (profile.minutes + 10).clamp(30, 90),
          )
        : profile;

    final ws = _workouts.state;
    final used = <String>{};
    final removed = <Workout>[];
    final added = <Workout>[];
    var loadUps = 0, swaps = 0, extras = 0;
    for (final d in days) {
      final current = ws.forWeekday(d).first;
      final r = _evolver.evolveDay(
        current: current,
        profile: evolved,
        cycle: c,
        pool: pool,
        byId: _catalog.byId,
        lastLoad: _progress.lastLoad,
        usedInPlan: used,
      );
      used.addAll(r.workout.items.map((i) => i.exerciseId));
      removed.add(current);
      added.add(r.workout);
      loadUps += r.loadUps;
      swaps += r.swaps;
      extras += r.added;
    }
    final archiveId = _workouts.apply(
      remove: removed,
      add: added,
      archiveLabel: global
          ? 'Antes da evolução ${c + 1}'
          : 'Antes de evoluir ${weekdayFull[onlyDay - 1]}',
    );
    if (global) {
      _planner.updateProfile(evolved);
      _store.setString(_cycleKey, '${c + 1}');
    }
    final parts = <String>[
      if (loadUps > 0) '$loadUps carga(s) maior(es)',
      if (swaps > 0) '$swaps variação(ões) nova(s)',
      if (extras > 0) '+$extras exercício(s)',
      if (global && nextLevel != profile.level)
        'nível ${levelNames[profile.level]} → ${levelNames[nextLevel]}',
    ];
    return PlanChange(
      removed: removed,
      added: added,
      archiveId: archiveId,
      profileBefore: global ? profile : null,
      cycleBefore: global ? c : null,
      summary: parts.isEmpty
          ? 'Plano evoluído (mais séries e menos descanso)'
          : 'Plano evoluído: ${parts.join(', ')}',
    );
  }

  /// Volta os treinos (e o perfil/ciclo, se a evolução os mudou).
  void undo(PlanChange change) {
    _workouts.undoApply(
      added: change.added,
      removed: change.removed,
      archiveId: change.archiveId,
    );
    final before = change.profileBefore;
    if (before != null) _planner.updateProfile(before);
    final cycleBefore = change.cycleBefore;
    if (cycleBefore != null) _store.setString(_cycleKey, '$cycleBefore');
  }

  String _nextLevel(String level) {
    final i = levelRank(level);
    return levelOrder[(i + 1).clamp(0, levelOrder.length - 1)];
  }
}
