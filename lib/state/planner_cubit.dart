import 'package:flutter_bloc/flutter_bloc.dart';

import '../ai/goal_text.dart';
import '../ai/relevance_ranker.dart';
import '../data/equipment/equipment_matcher.dart';
import '../data/gif_catalog.dart';
import '../data/storage/key_value_store.dart';
import '../domain/training/day_template.dart';
import '../domain/training/dual_cable.dart';
import '../domain/training/prescription.dart';
import '../domain/training/progression.dart';
import '../domain/training/recovery.dart';
import '../domain/training/split_planner.dart';
import '../domain/training/substitutes.dart';
import '../domain/training/training_profile.dart';
import '../domain/training/workout_generator.dart';
import '../models/day_focus.dart';
import '../models/exercise.dart';
import '../models/plan_item.dart';
import 'equipment_cubit.dart';
import 'planner_state.dart';
import 'progress_cubit.dart';
import 'workouts_cubit.dart';

const _profileKey = 'profile';
const _settingsKey = 'day_settings';
const _avoidKey = 'avoid_items';

/// Orquestra a geração do plano semanal (perfil, dias, foco e rascunhos).
class PlannerCubit extends Cubit<PlannerState> {
  final KeyValueStore _store;
  final EquipmentCubit _equipment;
  final WorkoutsCubit _workouts;
  final ProgressCubit _progress;
  final GifCatalog _gifs;
  final WorkoutGenerator _generator;
  final RelevanceRanker _keyword, _semantic;
  int _round = 0;

  PlannerCubit(
    this._store,
    this._equipment,
    this._workouts,
    this._progress,
    this._gifs,
    this._generator,
    this._keyword,
    this._semantic,
  ) : super(const PlannerState());

  List<int> get days => _workouts.state.sortedDays;

  void load() {
    final settings = <int, DaySetting>{};
    for (final e in _store.readMap(_settingsKey).entries) {
      final m = e.value as Map;
      settings[int.parse(e.key)] = DaySetting(
        focusById(m['f'] as String?).id,
        Set<String>.from(m['e'] ?? []),
      );
    }
    final profile = TrainingProfile.fromJson(_store.readMap(_profileKey));
    // dias sem foco salvo recebem a divisão sugerida
    for (final e in suggestSplit(days, profile).entries) {
      settings.putIfAbsent(e.key, () => DaySetting(e.value));
    }
    emit(
      state.copyWith(
        profile: profile,
        settings: settings,
        drafts: const {},
        avoidedItems: {...?_store.getStringList(_avoidKey)},
      ),
    );
  }

  void _persist(PlannerState next) {
    _store.writeMap(_profileKey, next.profile.toJson());
    _store.writeMap(_settingsKey, {
      for (final e in next.settings.entries)
        '${e.key}': {'f': e.value.focus, 'e': e.value.emphasis.toList()},
    });
    emit(next);
  }

  // ---------------------------------------------------------------- Configuração

  void setDays(Set<int> chosen) {
    _workouts.setTrainDays(chosen);
    _applySplit(
      state.copyWith(
        drafts: {...state.drafts}..removeWhere((d, _) => !chosen.contains(d)),
      ),
      state.profile,
    );
  }

  /// Aplica a divisão sugerida para os dias escolhidos.
  void autoSplit() => _applySplit(state, state.profile);

  void _applySplit(PlannerState base, TrainingProfile profile) {
    final split = suggestSplit(days, profile);
    _persist(
      base.copyWith(
        profile: profile,
        settings: {for (final e in split.entries) e.key: DaySetting(e.value)},
      ),
    );
  }

  void updateProfile(TrainingProfile profile) {
    if (profile.level != state.profile.level) {
      _applySplit(state, profile); // a divisão depende do nível
    } else {
      _persist(state.copyWith(profile: profile));
    }
  }

  /// Marca/desmarca um aparelho que não deve entrar nos treinos gerados.
  void toggleAvoid(String itemId) {
    final next = {...state.avoidedItems};
    next.contains(itemId) ? next.remove(itemId) : next.add(itemId);
    _store.setStringList(_avoidKey, next.toList());
    emit(state.copyWith(avoidedItems: next));
  }

  /// Exercícios possíveis: equipamentos salvos, menos os aparelhos evitados.
  List<Exercise> get pool {
    final noDualCable = state.avoidedItems.contains(dualCableKey);
    return [
      for (final e in _equipment.state.available)
        if (!state.avoidedItems.contains(itemForExercise(e)?.id) &&
            !(noDualCable && usesDualCable(e)))
          e,
    ];
  }

  void setSemantic(bool value) => emit(state.copyWith(useSemantic: value));

  void setFocus(int d, String focusId) => _persist(
    state.copyWith(settings: {...state.settings, d: DaySetting(focusId)}),
  );

  void toggleEmphasis(int d, String muscle) {
    final current = state.settings[d] ?? const DaySetting('full');
    final emphasis = {...current.emphasis};
    emphasis.contains(muscle) ? emphasis.remove(muscle) : emphasis.add(muscle);
    _persist(
      state.copyWith(
        settings: {...state.settings, d: DaySetting(current.focus, emphasis)},
      ),
    );
  }

  List<String> get warnings =>
      recoveryWarnings({for (final d in days) d: state.focusFor(d)});

  // ------------------------------------------------------------------- Geração

  Future<Map<String, double>> relevance(List<Exercise> pool) async {
    final text = state.profile.goalText.trim();
    if (text.isEmpty) return {};
    emit(
      state.copyWith(
        status: state.useSemantic
            ? 'Carregando IA no navegador (só na 1ª vez)...'
            : 'Interpretando seu objetivo...',
      ),
    );
    final ranker = state.useSemantic ? _semantic : _keyword;
    return ranker.scores(
      text,
      pool,
      onProgress: (p) => emit(state.copyWith(progress: p)),
    );
  }

  /// Gera o treino de um dia com o perfil atual (usado pelo planejador e por
  /// "Mudar plano"). Dá destaque aos músculos do dia e aos citados no objetivo.
  GeneratedDay buildDay({
    required int day,
    required DayFocus focus,
    required Set<String> avoid,
    required Map<String, double> relevance,
    required int seed,
  }) {
    final textMuscles = musclesFromText(state.profile.goalText);
    return _generator.generate(
      GenerationRequest(
        profile: state.profile,
        focus: focus,
        weekday: day,
        pool: pool,
        emphasis: {
          ...state.emphasisFor(day),
          ...textMuscles.where(focus.muscles.contains),
        },
        avoidIds: avoid,
        relevance: relevance,
        seed: seed,
        lastLoad: _progress.lastLoad,
        hasGif: (e) => _gifs.gifFor(e) != null,
      ),
    );
  }

  Future<void> generateWeek() => _generate(days);
  Future<void> generateDay(int d) => _generate([d]);

  Future<void> _generate(List<int> target) async {
    final pool = this.pool;
    if (state.busy || target.isEmpty) return;
    if (pool.isEmpty) {
      emit(
        state.copyWith(
          status: 'Todos os aparelhos disponíveis estão marcados para evitar.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        busy: true,
        progress: 0,
        status: target.length > 1
            ? 'Montando sua semana...'
            : 'Montando o treino do dia...',
      ),
    );
    // A geração é quase instantânea; a pausa deixa o carregamento visível.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    try {
      final scores = await relevance(pool);
      final drafts = {...state.drafts};
      _round++;
      for (final d in target) {
        final g = buildDay(
          day: d,
          focus: focusById(state.focusFor(d)),
          // evita repetir os outros dias e a versão anterior deste dia
          avoid: {
            for (final o in drafts.values)
              ...o.workout.items.map((i) => i.exerciseId),
          },
          relevance: scores,
          seed: _round * 7919 + d,
        );
        drafts[d] = DayDraft(g.workout, g.reasons);
      }
      emit(
        state.copyWith(
          drafts: drafts,
          status: scores.isNotEmpty && state.useSemantic
              ? 'Plano gerado com IA semântica'
              : 'Plano gerado',
        ),
      );
    } finally {
      emit(state.copyWith(busy: false));
    }
  }

  // ------------------------------------------------------------ Edição de rascunho

  List<Exercise> substitutesFor(Exercise current) {
    final used = {
      for (final d in state.drafts.values)
        ...d.workout.items.map((i) => i.exerciseId),
    };
    return suggestSubstitutes(
      current: current,
      pool: pool,
      exclude: used,
      profile: state.profile,
    );
  }

  void swapExercise(int day, int index, Exercise replacement) {
    final draft = state.drafts[day];
    if (draft == null) return;
    final old = draft.workout.items[index];
    draft.workout.items[index] = PlanItem(
      replacement.id,
      old.sets,
      old.reps,
      restSec: old.restSec,
      kg: _progress.lastLoad(replacement.id),
    );
    draft.reasons[replacement.id] = 'Troca sugerida do mesmo músculo';
    emit(state.copyWith(drafts: {...state.drafts}));
  }

  /// Acrescenta um exercício escolhido pelo usuário ao dia gerado.
  void addExercise(int day, Exercise e) {
    final draft = state.drafts[day];
    if (draft == null || draft.workout.items.any((i) => i.exerciseId == e.id)) {
      return;
    }
    final last = _progress.lastLoad(e.id);
    final p = prescribe(
      state.profile.goal,
      e.isCompound ? SlotRole.compound : SlotRole.isolation,
      state.profile.level,
    );
    draft.workout.items.add(
      e.isCardio
          ? PlanItem(e.id, 1, 20, restSec: 0)
          : PlanItem(
              e.id,
              p.sets,
              p.reps,
              restSec: p.restSec,
              kg: last == null ? null : nextLoad(last),
            ),
    );
    draft.reasons[e.id] = 'Adicionado por você';
    emit(state.copyWith(drafts: {...state.drafts}));
  }

  void removeExercise(int day, String exerciseId) {
    state.drafts[day]?.workout.items.removeWhere(
      (i) => i.exerciseId == exerciseId,
    );
    emit(state.copyWith(drafts: {...state.drafts}));
  }

  void removeItem(int day, int index) {
    state.drafts[day]?.workout.items.removeAt(index);
    emit(state.copyWith(drafts: {...state.drafts}));
  }

  void removeDraft(int day) =>
      emit(state.copyWith(drafts: {...state.drafts}..remove(day)));

  bool hasConflicts() => state.drafts.values.any(
    (d) => _workouts.state.forWeekday(d.workout.weekday!).isNotEmpty,
  );

  /// Salva os rascunhos como treinos e limpa o planejador.
  int commit({required bool replaceDays}) {
    final list = state.drafts.values.map((d) => d.workout).toList();
    _workouts.saveAll(list, replaceDays: replaceDays);
    emit(state.copyWith(drafts: const {}));
    return list.length;
  }
}
