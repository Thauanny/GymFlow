import '../storage/key_value_store.dart';
import 'backup_service.dart' show backupKeys;

/// O que "Apagar dados" pode remover.
enum ResetScope {
  workouts,
  progress,
  workoutsAndProgress,
  weight,
  equipment,
  all,
}

/// A semana, os planos anteriores, a divisão por dia e o ciclo de evolução.
const _workoutKeys = [
  'workouts',
  'train_days',
  'workout_history',
  'day_settings',
  'evolution_cycle',
];

/// Treinos feitos (calendário, constância, histórico) e as cargas usadas.
const _progressKeys = ['logs', 'loads'];

const _weightKeys = ['weights'];

/// Equipamentos, halteres e aparelhos a evitar.
const _equipmentKeys = ['equip2', 'dumbbells', 'avoid_items'];

/// Apaga partes dos dados salvos e manda o app recarregar o estado.
class DataResetService {
  final KeyValueStore _store;
  final void Function() _onReset;

  DataResetService(this._store, this._onReset);

  Future<void> reset(ResetScope scope) async {
    final keys = switch (scope) {
      ResetScope.workouts => _workoutKeys,
      ResetScope.progress => _progressKeys,
      ResetScope.workoutsAndProgress => [..._workoutKeys, ..._progressKeys],
      ResetScope.weight => _weightKeys,
      ResetScope.equipment => _equipmentKeys,
      ResetScope.all => backupKeys,
    };
    for (final key in keys) {
      await _store.remove(key);
    }
    _onReset();
  }
}
