import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/storage/key_value_store.dart';

const _key = 'theme_mode';

class ThemeCubit extends Cubit<ThemeMode> {
  final KeyValueStore _store;
  ThemeCubit(this._store) : super(ThemeMode.light);

  void load() =>
      emit(_store.getString(_key) == 'dark' ? ThemeMode.dark : ThemeMode.light);

  void toggle(Brightness current) {
    final next = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    _store.setString(_key, next == ThemeMode.light ? 'light' : 'dark');
    emit(next);
  }
}
