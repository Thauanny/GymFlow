import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/utils/format.dart';
import '../data/storage/key_value_store.dart';
import '../models/history.dart';
import '../models/workout.dart';

const _logsKey = 'logs';
const _weightsKey = 'weights';
const _loadsKey = 'loads';

class ProgressState {
  final List<LogEntry> logs;
  final List<WeightEntry> weights;
  final Map<String, double> loads;

  const ProgressState({
    this.logs = const [],
    this.weights = const [],
    this.loads = const {},
  });

  int get totalMinutes => logs.fold(0, (a, b) => a + b.minutes);

  Set<DateTime> get trainedDays => {for (final l in logs) dateOnly(l.date)};

  bool trainedOn(DateTime d) => trainedDays.contains(dateOnly(d));

  int get streakDays {
    final days = trainedDays;
    var d = dateOnly(DateTime.now());
    if (!days.contains(d)) d = d.subtract(const Duration(days: 1));
    var n = 0;
    while (days.contains(d)) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  /// Dias treinados nos últimos 7 dias.
  int get lastWeekCount {
    final from = dateOnly(DateTime.now()).subtract(const Duration(days: 6));
    return trainedDays.where((d) => !d.isBefore(from)).length;
  }
}

/// Histórico de treinos, peso corporal e últimas cargas por exercício.
class ProgressCubit extends Cubit<ProgressState> {
  final KeyValueStore _store;
  ProgressCubit(this._store) : super(const ProgressState());

  void load() => emit(
    ProgressState(
      logs: _store.readList(_logsKey, LogEntry.fromJson),
      weights: _store.readList(_weightsKey, WeightEntry.fromJson),
      loads: {
        for (final e in _store.readMap(_loadsKey).entries)
          e.key: (e.value as num).toDouble(),
      },
    ),
  );

  /// Registra um treino concluído e guarda as cargas usadas.
  void finish(Workout w, int minutes) {
    final logs = [
      LogEntry(DateTime.now(), w.name, w.items.length, minutes),
      ...state.logs,
    ];
    final loads = {...state.loads};
    for (final i in w.items) {
      if (i.done && i.kg != null) loads[i.exerciseId] = i.kg!;
    }
    _store.writeList(_logsKey, logs.map((e) => e.toJson()));
    _store.writeMap(_loadsKey, loads);
    emit(ProgressState(logs: logs, weights: state.weights, loads: loads));
  }

  void addWeight(double kg) {
    final weights = [...state.weights, WeightEntry(DateTime.now(), kg)];
    _store.writeList(_weightsKey, weights.map((e) => e.toJson()));
    emit(ProgressState(logs: state.logs, weights: weights, loads: state.loads));
  }

  double? lastLoad(String exerciseId) => state.loads[exerciseId];
}
