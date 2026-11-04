import 'dart:async';

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/equipment/equipment_catalog.dart';
import '../data/equipment/equipment_matcher.dart';
import '../data/storage/key_value_store.dart';
import '../domain/training/training_profile.dart';
import '../models/exercise.dart';
import 'catalog_cubit.dart';

const _equipKey = 'equip2';
const _dumbbellKey = 'dumbbells';

/// `equipment` é a seleção em edição; `saved` é a última confirmada.
class EquipmentState {
  final Set<String> equipment, saved;
  final Set<int> dumbbells, savedDumbbells;
  final List<Exercise> available, draftAvailable;
  final Map<String, int> counts;

  const EquipmentState({
    this.equipment = const {},
    this.saved = const {},
    this.dumbbells = const {},
    this.savedDumbbells = const {},
    this.available = const [],
    this.draftAvailable = const [],
    this.counts = const {},
  });

  bool get dirty =>
      !setEquals(equipment, saved) || !setEquals(dumbbells, savedDumbbells);

  EquipmentState copyWith({
    Set<String>? equipment,
    Set<String>? saved,
    Set<int>? dumbbells,
    Set<int>? savedDumbbells,
    List<Exercise>? available,
    List<Exercise>? draftAvailable,
    Map<String, int>? counts,
  }) => EquipmentState(
    equipment: equipment ?? this.equipment,
    saved: saved ?? this.saved,
    dumbbells: dumbbells ?? this.dumbbells,
    savedDumbbells: savedDumbbells ?? this.savedDumbbells,
    available: available ?? this.available,
    draftAvailable: draftAvailable ?? this.draftAvailable,
    counts: counts ?? this.counts,
  );
}

/// Equipamentos que existem na academia do usuário.
class EquipmentCubit extends Cubit<EquipmentState> {
  final KeyValueStore _store;
  final CatalogCubit _catalog;
  late final StreamSubscription<CatalogState> _sub;

  EquipmentCubit(this._store, this._catalog) : super(const EquipmentState()) {
    _sub = _catalog.stream.listen((_) => _refresh());
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }

  void load() {
    final valid = equipItems.map((i) => i.id).toSet();
    final stored = _store.getStringList(_equipKey) ?? [];
    final equipment = {
      ...stored.where(valid.contains),
      // formato antigo: 'dumbbell' representava todos os halteres
      if (stored.contains('dumbbell'))
        ...equipItems.where((i) => i.dbEquip == 'dumbbell').map((i) => i.id),
    };
    final dumbbells = _store.readIntSet(_dumbbellKey);
    emit(
      state.copyWith(
        equipment: equipment,
        saved: {...equipment},
        dumbbells: dumbbells,
        savedDumbbells: {...dumbbells},
      ),
    );
    _refresh();
  }

  List<Exercise> _availableFor(Set<String> ids) {
    final sel = equipItems.where((i) => ids.contains(i.id)).toList();
    return _catalog.state.exercises
        .where((e) => sel.any((i) => itemMatches(i, e)))
        .toList();
  }

  /// Recalcula tudo que depende da base de exercícios.
  void _refresh() {
    final all = _catalog.state.exercises;
    emit(
      state.copyWith(
        available: _availableFor(state.saved),
        draftAvailable: _availableFor(state.equipment),
        counts: {
          for (final it in equipItems)
            it.id: all.where((e) => itemMatches(it, e)).length,
        },
      ),
    );
  }

  void _setDraft(Set<String> equipment) => emit(
    state.copyWith(
      equipment: equipment,
      draftAvailable: _availableFor(equipment),
    ),
  );

  void toggle(String id) {
    final next = {...state.equipment};
    next.contains(id) ? next.remove(id) : next.add(id);
    _setDraft(next);
  }

  void setAll(Set<String> ids) => _setDraft({...ids});

  /// Troca um aparelho por outro (ou só adiciona, se [removeId] for nulo).
  void swap(String? removeId, String addId) {
    final next = {...state.equipment}..remove(removeId);
    _setDraft(next..add(addId));
  }

  void toggleDumbbell(int kg) {
    final next = {...state.dumbbells};
    next.contains(kg) ? next.remove(kg) : next.add(kg);
    emit(state.copyWith(dumbbells: next));
  }

  /// Confirma a seleção e grava no armazenamento local.
  void save() {
    _store.setStringList(_equipKey, state.equipment.toList());
    _store.writeIntSet(_dumbbellKey, state.dumbbells);
    emit(
      state.copyWith(
        saved: {...state.equipment},
        savedDumbbells: {...state.dumbbells},
        available: state.draftAvailable,
      ),
    );
  }

  /// Halter sugerido (kg) entre os que o usuário tem, conforme o objetivo.
  int? dumbbellFor(TrainingGoal goal) {
    if (state.dumbbells.isEmpty) return null;
    final s = state.dumbbells.toList()..sort();
    final f = switch (goal) {
      TrainingGoal.strength => .75,
      TrainingGoal.endurance => .25,
      _ => .5,
    };
    return s[((s.length - 1) * f).round()];
  }
}
