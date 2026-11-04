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

  Exercise? byId(String id) => state.byId[id];
}
