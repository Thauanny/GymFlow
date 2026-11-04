import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Armazenamento chave-valor simples (permite trocar por um fake nos testes).
abstract class KeyValueStore {
  /// Valor cru da chave (texto, lista de textos ou nulo), sem exigir o tipo.
  Object? get(String key);
  String? getString(String key);
  List<String>? getStringList(String key);
  Future<void> setString(String key, String value);
  Future<void> setStringList(String key, List<String> value);
  Future<void> remove(String key);
}

class PrefsStore implements KeyValueStore {
  final SharedPreferences _p;
  PrefsStore._(this._p);

  static Future<PrefsStore> open() async =>
      PrefsStore._(await SharedPreferences.getInstance());

  @override
  Object? get(String key) => _p.get(key);
  @override
  String? getString(String key) => _p.getString(key);
  @override
  List<String>? getStringList(String key) => _p.getStringList(key);
  @override
  Future<void> setString(String key, String value) => _p.setString(key, value);
  @override
  Future<void> setStringList(String key, List<String> value) =>
      _p.setStringList(key, value);
  @override
  Future<void> remove(String key) => _p.remove(key);
}

class MemoryStore implements KeyValueStore {
  final Map<String, Object> _m = {};

  @override
  Object? get(String key) => _m[key];
  @override
  String? getString(String key) => _m[key] as String?;
  @override
  List<String>? getStringList(String key) => _m[key] as List<String>?;
  @override
  Future<void> setString(String key, String value) async => _m[key] = value;
  @override
  Future<void> setStringList(String key, List<String> value) async =>
      _m[key] = value;
  @override
  Future<void> remove(String key) async => _m.remove(key);
}

extension JsonStore on KeyValueStore {
  List<T> readList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final s = getString(key);
    if (s == null) return [];
    try {
      return (jsonDecode(s) as List)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> writeList(String key, Iterable<Map<String, dynamic>> items) =>
      setString(key, jsonEncode(items.toList()));

  Map<String, dynamic> readMap(String key) {
    final s = getString(key);
    if (s == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(s) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> writeMap(String key, Map<String, dynamic> value) =>
      setString(key, jsonEncode(value));

  Set<int> readIntSet(String key) =>
      (getStringList(key) ?? []).map(int.parse).toSet();

  Future<void> writeIntSet(String key, Set<int> v) =>
      setStringList(key, v.map((e) => '$e').toList());
}
