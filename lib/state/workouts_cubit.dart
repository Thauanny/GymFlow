import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/storage/key_value_store.dart';
import '../models/archived_plan.dart';
import '../models/workout.dart';

const _workoutsKey = 'workouts';
const _daysKey = 'train_days';
const _historyKey = 'workout_history';
const _historyLimit = 30;

class WorkoutsState {
  final List<Workout> workouts;
  final Set<int> trainDays;

  /// Histórico: treinos substituídos, do mais recente para o mais antigo.
  final List<ArchivedPlan> archive;

  const WorkoutsState({
    this.workouts = const [],
    this.trainDays = const {},
    this.archive = const [],
  });

  WorkoutsState copyWith({
    List<Workout>? workouts,
    Set<int>? trainDays,
    List<ArchivedPlan>? archive,
  }) => WorkoutsState(
    workouts: workouts ?? this.workouts,
    trainDays: trainDays ?? this.trainDays,
    archive: archive ?? this.archive,
  );

  List<int> get sortedDays => trainDays.toList()..sort();

  List<Workout> forWeekday(int d) =>
      workouts.where((w) => w.weekday == d).toList();

  List<Workout> get withoutDay =>
      workouts.where((w) => w.weekday == null).toList();

  /// Dias escolhidos que ainda não têm treino.
  List<int> get missingDays => [
    for (final d in sortedDays)
      if (forWeekday(d).isEmpty) d,
  ];
}

/// Treinos salvos, os dias da semana em que o usuário treina e o histórico dos
/// treinos que já foram substituídos.
class WorkoutsCubit extends Cubit<WorkoutsState> {
  final KeyValueStore _store;
  WorkoutsCubit(this._store) : super(const WorkoutsState());

  void load() => emit(
    WorkoutsState(
      workouts: _store.readList(_workoutsKey, Workout.fromJson),
      trainDays: _store.readIntSet(_daysKey),
      archive: _store.readList(_historyKey, ArchivedPlan.fromJson),
    ),
  );

  void _setWorkouts(List<Workout> list, {List<ArchivedPlan>? archive}) {
    _store.writeList(_workoutsKey, list.map((w) => w.toJson()));
    if (archive != null) {
      _store.writeList(_historyKey, archive.map((a) => a.toJson()));
    }
    emit(state.copyWith(workouts: list, archive: archive));
  }

  /// Guarda [workouts] no histórico; devolve o novo estado do histórico.
  List<ArchivedPlan> _archived(
    List<Workout> workouts,
    String label,
    String id,
  ) {
    if (workouts.isEmpty) return state.archive;
    final entry = ArchivedPlan(
      id: id,
      date: DateTime.now(),
      label: label,
      workouts: [for (final w in workouts) Workout.fromJson(w.toJson())],
    );
    return [entry, ...state.archive].take(_historyLimit).toList();
  }

  /// Grava alterações feitas diretamente num treino (ex.: marcar séries).
  void touch() => _setWorkouts([...state.workouts]);

  /// Insere um treino novo ou substitui o existente (mesmo id).
  void save(Workout w) {
    final list = [...state.workouts];
    final i = list.indexWhere((x) => x.id == w.id);
    i >= 0 ? list[i] = w : list.insert(0, w);
    _setWorkouts(list);
  }

  /// Exclusão pedida pelo usuário: não vai para o histórico.
  void delete(Workout w) =>
      _setWorkouts([...state.workouts]..removeWhere((x) => x.id == w.id));

  /// Salva vários treinos. Com [replaceDays], os existentes nesses dias saem
  /// e vão para o histórico (como "Plano anterior").
  void saveAll(List<Workout> incoming, {bool replaceDays = false}) {
    final days = incoming.map((w) => w.weekday).toSet();
    final replaced = replaceDays
        ? state.workouts.where((w) => days.contains(w.weekday)).toList()
        : <Workout>[];
    final kept = state.workouts.where((w) => !replaced.contains(w));
    _setWorkouts(
      [...incoming, ...kept],
      archive: replaced.isEmpty
          ? null
          : _archived(replaced, 'Plano anterior', _newId()),
    );
  }

  /// Troca treinos: os de [remove] saem (e vão para o histórico, se houver
  /// [archiveLabel]) e os de [add] entram. Devolve o id da entrada do histórico.
  String? apply({
    required List<Workout> remove,
    required List<Workout> add,
    String? archiveLabel,
  }) {
    final ids = remove.map((w) => w.id).toSet();
    final id = archiveLabel == null || remove.isEmpty ? null : _newId();
    _setWorkouts([
      ...add,
      for (final w in state.workouts)
        if (!ids.contains(w.id)) w,
    ], archive: id == null ? null : _archived(remove, archiveLabel!, id));
    return id;
  }

  /// Desfaz um [apply]: os treinos de [added] saem, os de [removed] voltam e a
  /// entrada do histórico criada por ele ([archiveId]) é apagada.
  void undoApply({
    required List<Workout> added,
    required List<Workout> removed,
    String? archiveId,
  }) {
    final ids = added.map((w) => w.id).toSet();
    _setWorkouts(
      [
        ...removed,
        for (final w in state.workouts)
          if (!ids.contains(w.id)) w,
      ],
      archive: archiveId == null
          ? null
          : [
              for (final a in state.archive)
                if (a.id != archiveId) a,
            ],
    );
  }

  /// Traz um plano do histórico de volta. Os treinos que ocupavam esses dias
  /// vão para o histórico ("Antes de restaurar").
  void restoreArchived(ArchivedPlan plan) {
    final current = [
      for (final w in state.workouts)
        if (plan.weekdays.contains(w.weekday)) w,
    ];
    final withoutPlan = [
      for (final a in state.archive)
        if (a.id != plan.id) a,
    ];
    final ids = current.map((w) => w.id).toSet();
    final archive = current.isEmpty
        ? withoutPlan
        : [
            ArchivedPlan(
              id: _newId(),
              date: DateTime.now(),
              label: 'Antes de restaurar',
              workouts: [for (final w in current) Workout.fromJson(w.toJson())],
            ),
            ...withoutPlan,
          ].take(_historyLimit).toList();
    _setWorkouts([
      ...plan.workouts,
      for (final w in state.workouts)
        if (!ids.contains(w.id)) w,
    ], archive: archive);
  }

  void deleteArchived(String id) => _setArchive([
    for (final a in state.archive)
      if (a.id != id) a,
  ]);

  /// Tira um treino de um plano do histórico; se era o último, apaga o plano.
  void deleteArchivedWorkout(String planId, String workoutId) {
    final archive = <ArchivedPlan>[];
    for (final a in state.archive) {
      if (a.id != planId) {
        archive.add(a);
        continue;
      }
      final rest = [
        for (final w in a.workouts)
          if (w.id != workoutId) w,
      ];
      if (rest.isNotEmpty) {
        archive.add(
          ArchivedPlan(id: a.id, date: a.date, label: a.label, workouts: rest),
        );
      }
    }
    _setArchive(archive);
  }

  void _setArchive(List<ArchivedPlan> archive) {
    _store.writeList(_historyKey, archive.map((a) => a.toJson()));
    emit(state.copyWith(archive: archive));
  }

  void setTrainDays(Set<int> days) {
    _store.writeIntSet(_daysKey, days);
    emit(state.copyWith(trainDays: {...days}));
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
