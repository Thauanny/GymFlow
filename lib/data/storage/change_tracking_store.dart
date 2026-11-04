import 'key_value_store.dart';

/// Repassa tudo para [_inner] e avisa [_onChange] a cada gravação ou remoção
/// de uma chave que [_tracks] aceita (qualquer alteração nos dados do app).
class ChangeTrackingStore implements KeyValueStore {
  final KeyValueStore _inner;
  final bool Function(String key) _tracks;
  final void Function() _onChange;

  ChangeTrackingStore(
    this._inner, {
    required bool Function(String key) tracks,
    required void Function() onChange,
  }) : _tracks = tracks,
       _onChange = onChange;

  Future<void> _after(String key, Future<void> write) {
    if (_tracks(key)) _onChange();
    return write;
  }

  @override
  Object? get(String key) => _inner.get(key);
  @override
  String? getString(String key) => _inner.getString(key);
  @override
  List<String>? getStringList(String key) => _inner.getStringList(key);
  @override
  Future<void> setString(String key, String value) =>
      _after(key, _inner.setString(key, value));
  @override
  Future<void> setStringList(String key, List<String> value) =>
      _after(key, _inner.setStringList(key, value));
  @override
  Future<void> remove(String key) => _after(key, _inner.remove(key));
}
