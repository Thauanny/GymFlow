import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../storage/key_value_store.dart';

/// Todas as chaves do app no armazenamento local (o que entra no backup).
const backupKeys = [
  'equip2',
  'dumbbells',
  'workouts',
  'train_days',
  'workout_history',
  'logs',
  'weights',
  'loads',
  'profile',
  'day_settings',
  'avoid_items',
  'evolution_cycle',
  'theme_mode',
];

const _lastBackupKey = 'last_backup';
const _lastChangeKey = 'last_change';
const _dismissedKey = 'backup_notice_dismissed';
const _formatVersion = 1;

/// Mudar o tema não conta como alteração que mereça backup.
bool isTrackedBackupKey(String key) =>
    key != 'theme_mode' && backupKeys.contains(key);

class BackupException implements Exception {
  final String message;
  const BackupException(this.message);
  @override
  String toString() => message;
}

/// Backup dos dados do app em um arquivo JSON, guardado fora do navegador
/// (o armazenamento local pode ser apagado ao limpar os dados do site).
class BackupService {
  final KeyValueStore _store;
  final void Function() _onImported;
  final DateTime Function() _now;

  BackupService(this._store, this._onImported, {DateTime Function()? now})
    : _now = now ?? DateTime.now {
    _changes = ValueNotifier(lastBackup);
    _reminder = ValueNotifier(_computeReminder());
  }

  late final ValueNotifier<DateTime?> _changes;
  late final ValueNotifier<bool> _reminder;
  bool _importing = false;

  /// Avisa quando um backup é exportado (para atualizar avisos na tela).
  ValueListenable<DateTime?> get changes => _changes;

  /// Deve aparecer o aviso para fazer backup? (alterações sem backup, ou
  /// backup antigo, e o aviso não foi dispensado.)
  ValueListenable<bool> get reminder => _reminder;

  /// Data do último backup exportado (null se nunca).
  DateTime? get lastBackup => _date(_lastBackupKey);

  DateTime? _date(String key) {
    final s = _store.getString(key);
    return s == null ? null : DateTime.tryParse(s);
  }

  /// Houve alteração nos dados depois do último backup (ou sem nunca ter feito)?
  bool get hasChangesSinceBackup {
    final changed = _date(_lastChangeKey);
    final backed = lastBackup;
    return changed != null && (backed == null || changed.isAfter(backed));
  }

  /// Só vale lembrar de backup quando há algo que doeria perder: treinos,
  /// histórico, cargas ou peso. Só escolher equipamentos ou dias não conta.
  static const _valuableKeys = [
    'workouts',
    'workout_history',
    'logs',
    'weights',
    'loads',
  ];

  bool get _hasData => _valuableKeys.any((k) {
    final v = _store.get(k);
    if (v is List) return v.isNotEmpty;
    return v is String && v.isNotEmpty && v != '[]' && v != '{}';
  });

  bool _computeReminder() {
    if (!_hasData) return false;
    final changed = hasChangesSinceBackup;
    if (!changed && !needsBackup(hasData: true)) return false;
    final dismissed = _date(_dismissedKey);
    final lastChange = _date(_lastChangeKey);
    return dismissed == null ||
        (lastChange != null && lastChange.isAfter(dismissed));
  }

  /// Registra uma alteração nos dados (chamado a cada gravação de dados do app).
  void markChanged() {
    if (_importing) return;
    _store.setString(_lastChangeKey, _now().toIso8601String());
    _reminder.value = _computeReminder();
  }

  /// Esconde o aviso até a próxima alteração.
  void dismissReminder() {
    _store.setString(_dismissedKey, _now().toIso8601String());
    _reminder.value = _computeReminder();
  }

  /// Há dados para proteger e o último backup é antigo (ou nunca foi feito)?
  bool needsBackup({required bool hasData, int maxDays = 14}) {
    if (!hasData) return false;
    final last = lastBackup;
    return last == null || _now().difference(last).inDays >= maxDays;
  }

  /// Gera o conteúdo do arquivo e registra a data do backup.
  String export() {
    final data = <String, dynamic>{};
    for (final key in backupKeys) {
      final value = _store.get(key);
      if (value is List) {
        data[key] = {'type': 'list', 'value': List<String>.from(value)};
      } else if (value is String) {
        data[key] = {'type': 'string', 'value': value};
      }
    }
    final now = _now();
    _store.setString(_lastBackupKey, now.toIso8601String());
    _changes.value = now;
    _reminder.value = _computeReminder();
    return const JsonEncoder.withIndent('  ').convert({
      'app': 'gymflow',
      'version': _formatVersion,
      'exportedAt': now.toIso8601String(),
      'data': data,
    });
  }

  /// Nome sugerido para o arquivo, ex.: `gymflow-backup-2026-11-03.json`.
  String get fileName {
    final d = _now();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'gymflow-backup-${d.year}-${two(d.month)}-${two(d.day)}.json';
  }

  /// Restaura os dados de um arquivo de backup. Lança [BackupException] se o
  /// arquivo não for válido (nada é alterado nesse caso).
  Future<int> import(String content) async {
    final Map<String, dynamic> file;
    try {
      file = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      throw const BackupException('Esse arquivo não é um backup do GymFlow.');
    }
    if (file['app'] != 'gymflow' || file['data'] is! Map) {
      throw const BackupException('Esse arquivo não é um backup do GymFlow.');
    }
    if ((file['version'] as int? ?? 0) > _formatVersion) {
      throw const BackupException(
        'Esse backup é de uma versão mais nova do app. Atualize o GymFlow.',
      );
    }
    final data = Map<String, dynamic>.from(file['data'] as Map);
    // valida tudo antes de gravar qualquer coisa
    final entries = <String, Map<String, dynamic>>{};
    for (final key in backupKeys) {
      final item = data[key];
      if (item == null) continue;
      final map = item as Map;
      final type = map['type'];
      final value = map['value'];
      final ok =
          (type == 'list' && value is List) ||
          (type == 'string' && value is String);
      if (!ok) throw BackupException('Backup danificado (item "$key").');
      entries[key] = Map<String, dynamic>.from(map);
    }
    // restaurar o backup n\u00e3o conta como altera\u00e7\u00e3o nova
    _importing = true;
    try {
      for (final e in entries.entries) {
        final value = e.value['value'];
        e.value['type'] == 'list'
            ? await _store.setStringList(
                e.key,
                List<String>.from(value as List),
              )
            : await _store.setString(e.key, value as String);
      }
    } finally {
      _importing = false;
    }
    _onImported();
    _reminder.value = _computeReminder();
    return entries.length;
  }
}
