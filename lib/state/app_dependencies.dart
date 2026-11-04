import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../ai/relevance_ranker.dart';
import '../ai/semantic_ranker_factory.dart';
import '../data/alternatives_service.dart';
import '../data/exercise_repository.dart';
import '../data/gif_catalog.dart';
import '../data/storage/change_tracking_store.dart';
import '../data/storage/key_value_store.dart';
import '../domain/training/workout_generator.dart';
import '../data/backup/backup_service.dart';
import '../data/backup/data_reset.dart';
import 'catalog_cubit.dart';
import 'equipment_cubit.dart';
import 'nav_cubit.dart';
import '../domain/training/plan_evolver.dart';
import 'plan_actions.dart';
import 'planner_cubit.dart';
import 'progress_cubit.dart';
import 'theme_cubit.dart';
import 'workouts_cubit.dart';

/// Monta o grafo de dependências e os Blocs, e os provê para a árvore de widgets.
class AppDependencies {
  final KeyValueStore store;
  final GifCatalog gifs;
  final AlternativesService alternatives;
  final PlanActions planActions;
  final BackupService backup;
  final DataResetService dataReset;
  final CatalogCubit catalog;
  final EquipmentCubit equipment;
  final WorkoutsCubit workouts;
  final ProgressCubit progress;
  final PlannerCubit planner;
  final ThemeCubit theme;
  final NavCubit nav = NavCubit();

  AppDependencies._({
    required this.store,
    required this.gifs,
    required this.alternatives,
    required this.planActions,
    required this.backup,
    required this.dataReset,
    required this.catalog,
    required this.equipment,
    required this.workouts,
    required this.progress,
    required this.planner,
    required this.theme,
  });

  static Future<AppDependencies> create() async {
    // toda gravação de dados do app conta como alteração sem backup
    BackupService? backupRef;
    final store = ChangeTrackingStore(
      await PrefsStore.open(),
      tracks: isTrackedBackupKey,
      onChange: () => backupRef?.markChanged(),
    );
    final gifs = GifCatalog();
    final catalog = CatalogCubit(ExerciseRepository());
    final equipment = EquipmentCubit(store, catalog);
    final workouts = WorkoutsCubit(store);
    final progress = ProgressCubit(store);
    final planner = PlannerCubit(
      store,
      equipment,
      workouts,
      progress,
      gifs,
      WorkoutGenerator(),
      KeywordRanker(),
      createSemanticRanker(),
    );
    final theme = ThemeCubit(store);
    // depois de importar ou apagar dados, recarrega o estado do armazenamento
    void reload() {
      equipment.load();
      workouts.load();
      progress.load();
      planner.load();
      theme.load();
    }

    final backup = BackupService(store, reload);
    backupRef = backup;
    final deps = AppDependencies._(
      store: store,
      gifs: gifs,
      alternatives: AlternativesService(gifs, () => catalog.state.exercises),
      catalog: catalog,
      equipment: equipment,
      workouts: workouts,
      progress: progress,
      planner: planner,
      planActions: PlanActions(
        store,
        catalog,
        workouts,
        progress,
        planner,
        PlanEvolver(),
      ),
      theme: theme,
      backup: backup,
      dataReset: DataResetService(store, reload),
    );
    await deps._load();
    return deps;
  }

  Future<void> _load() async {
    await gifs.load();
    await catalog.load();
    equipment.load();
    workouts.load();
    progress.load();
    planner.load();
    theme.load();
  }

  /// Provê serviços e Blocs para [child].
  Widget provide({required Widget child}) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: gifs),
      RepositoryProvider.value(value: alternatives),
      RepositoryProvider.value(value: planActions),
      RepositoryProvider.value(value: backup),
      RepositoryProvider.value(value: dataReset),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: catalog),
        BlocProvider.value(value: equipment),
        BlocProvider.value(value: workouts),
        BlocProvider.value(value: progress),
        BlocProvider.value(value: planner),
        BlocProvider.value(value: theme),
        BlocProvider.value(value: nav),
      ],
      child: child,
    ),
  );
}
