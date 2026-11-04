import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/exercise_repository.dart';
import '../models/exercise.dart';

class CatalogState {
  final bool loading;
  final String? error;
  final List<Exercise> exercises;
  final Map<String, Exercise> byId;

  const CatalogState({
    this.loading = true,
    this.error,
    this.exercises = const [],
    this.byId = const {},
  });
}

/// Base de exercícios carregada em memória.
class CatalogCubit extends Cubit<CatalogState> {
  final ExerciseRepository _repo;
  CatalogCubit(this._repo) : super(const CatalogState());

  Future<void> load() async {
    emit(const CatalogState());
    try {
      final list = await _repo.load();
      emit(
        CatalogState(
          loading: false,
          exercises: list,
          byId: {for (final e in list) e.id: e},
        ),
      );
    } catch (e) {
      emit(
        CatalogState(
          loading: false,
          error: 'Não foi possível carregar a base de exercícios: $e',
        ),
      );
    }
  }

  /// Acrescenta exercícios que não vieram da base principal (ex.: os que só
  /// têm GIF). Seguro de chamar de novo: ignora ids que já existem.
  void addExtra(List<Exercise> extra) {
    final fresh = [
      for (final e in extra)
        if (!state.byId.containsKey(e.id)) e,
    ];
    if (fresh.isEmpty) return;
    final list = [...state.exercises, ...fresh];
    emit(
      CatalogState(
        loading: false,
        exercises: list,
        byId: {for (final e in list) e.id: e},
      ),
    );
  }

  Exercise? byId(String id) => state.byId[id];
}
