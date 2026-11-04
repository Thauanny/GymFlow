import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/data/backup/backup_service.dart';
import 'package:gymflow/data/storage/key_value_store.dart';

void main() {
  late MemoryStore store;
  late int reloads;
  late DateTime now;
  late BackupService backup;

  setUp(() {
    store = MemoryStore();
    reloads = 0;
    now = DateTime(2026, 11, 3, 10);
    backup = BackupService(store, () => reloads++, now: () => now);
  });

  Future<void> seed() async {
    await store.setString('workouts', '[{"id":"1"}]');
    await store.setStringList('equip2', ['m_legpress', 'b_bench']);
    await store.setString('logs', '[]');
  }

  test('exporta strings e listas, com data e nome do arquivo', () async {
    await seed();
    final file = jsonDecode(backup.export()) as Map<String, dynamic>;
    expect(file['app'], 'gymflow');
    final data = file['data'] as Map<String, dynamic>;
    expect(data['workouts'], {'type': 'string', 'value': '[{"id":"1"}]'});
    expect(data['equip2'], {
      'type': 'list',
      'value': ['m_legpress', 'b_bench'],
    });
    expect(data.containsKey('weights'), isFalse); // sem dados, fica de fora
    expect(backup.fileName, 'gymflow-backup-2026-11-03.json');
    expect(backup.lastBackup, now);
  });

  test(
    'importar restaura tudo num armazenamento vazio e recarrega o app',
    () async {
      await seed();
      final content = backup.export();

      final fresh = MemoryStore(); // como se o navegador tivesse sido limpo
      var reloaded = false;
      final other = BackupService(fresh, () => reloaded = true);
      final n = await other.import(content);

      expect(n, 3);
      expect(reloaded, isTrue);
      expect(fresh.getString('workouts'), '[{"id":"1"}]');
      expect(fresh.getStringList('equip2'), ['m_legpress', 'b_bench']);
    },
  );

  test('arquivo inválido é recusado sem alterar nada', () async {
    await seed();
    for (final bad in [
      'isso não é json',
      '{"app":"outro","data":{}}',
      '{"app":"gymflow","version":1,"data":{"workouts":{"type":"list","value":"x"}}}',
      '{"app":"gymflow","version":99,"data":{}}',
    ]) {
      await expectLater(backup.import(bad), throwsA(isA<BackupException>()));
    }
    expect(store.getString('workouts'), '[{"id":"1"}]');
    expect(reloads, 0);
  });

  test('lembrete: só se há dados e o backup é antigo ou não existe', () async {
    expect(backup.needsBackup(hasData: false), isFalse);
    expect(backup.needsBackup(hasData: true), isTrue); // nunca fez
    backup.export();
    expect(backup.needsBackup(hasData: true), isFalse);
    now = now.add(const Duration(days: 15));
    expect(backup.needsBackup(hasData: true), isTrue);
  });
}
