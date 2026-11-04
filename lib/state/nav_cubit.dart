import 'package:flutter_bloc/flutter_bloc.dart';

enum AppTab { home, workouts, equipment, explore, progress }

/// Aba atual da navegação principal.
class NavCubit extends Cubit<AppTab> {
  NavCubit() : super(_fromUrl());

  /// Permite abrir direto numa aba: `.../?tab=equipment`.
  static AppTab _fromUrl() {
    final name = Uri.base.queryParameters['tab'];
    return AppTab.values.where((t) => t.name == name).firstOrNull ??
        AppTab.home;
  }

  void go(AppTab tab) => emit(tab);
}
