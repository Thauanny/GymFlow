import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/core/theme/app_theme.dart';
import 'package:gymflow/data/backup/backup_service.dart';
import 'package:gymflow/data/backup/data_reset.dart';
import 'package:gymflow/data/storage/change_tracking_store.dart';
import 'package:gymflow/data/storage/key_value_store.dart';
import 'package:gymflow/state/app_dependencies.dart';
import 'package:gymflow/ui/shell/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('aviso de backup (serviço)', () {
    late DateTime now;
    late ChangeTrackingStore store;
    late BackupService backup;

    setUp(() {
      now = DateTime(2026, 11, 3, 10);
      BackupService? ref;
      store = ChangeTrackingStore(
        MemoryStore(),
        tracks: isTrackedBackupKey,
        onChange: () => ref?.markChanged(),
      );
      backup = BackupService(store, () {}, now: () => now);
      ref = backup;
    });

    void later() => now = now.add(const Duration(minutes: 1));

    test('sem dados, ou só mudando o tema, não avisa', () async {
      expect(backup.reminder.value, isFalse);
      await store.setString('theme_mode', 'dark');
      expect(backup.reminder.value, isFalse);
      expect(backup.hasChangesSinceBackup, isFalse);
    });

    test('qualquer alteração nos dados mostra o aviso', () async {
      for (final write in <Future<void> Function()>[
        () => store.setString('weights', '[{"d":"2026-11-03","k":70}]'),
        () => store.setString('workouts', '[{"id":"1"}]'),
        () => store.setStringList('equip2', ['m_legpress']),
        () => store.setString('logs', '[{"d":"2026-11-03"}]'),
      ]) {
        backup.export(); // zera o aviso
        later();
        await write();
        expect(backup.reminder.value, isTrue);
        expect(backup.hasChangesSinceBackup, isTrue);
        later();
      }
    });

    test('exportar o backup esconde o aviso até a próxima alteração', () async {
      await store.setString('weights', '[{"d":"2026-11-03","k":70}]');
      expect(backup.reminder.value, isTrue);

      backup.export();
      expect(backup.reminder.value, isFalse);

      later();
      await store.setString('weights', '[{"d":"2026-11-03","k":71}]');
      expect(backup.reminder.value, isTrue);
    });

    test('dispensar esconde o aviso até a próxima alteração', () async {
      await store.setString('workouts', '[{"id":"1"}]');
      later();
      backup.dismissReminder();
      expect(backup.reminder.value, isFalse);

      later();
      await store.setString('workouts', '[{"id":"1"},{"id":"2"}]');
      expect(backup.reminder.value, isTrue);
    });

    test('restaurar um backup não conta como alteração', () async {
      final source = MemoryStore();
      await source.setString('workouts', '[{"id":"1"}]');
      final content = BackupService(source, () {}, now: () => now).export();

      await backup.import(content);
      expect(backup.hasChangesSinceBackup, isFalse);
    });

    test('apagar tudo esconde o aviso (não há o que proteger)', () async {
      await store.setString('workouts', '[{"id":"1"}]');
      expect(backup.reminder.value, isTrue);

      await DataResetService(store, () {}).reset(ResetScope.all);
      expect(backup.reminder.value, isFalse);
    });
  });

  testWidgets('aviso na tela leva ao backup e some depois de exportar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final d = (await tester.runAsync(AppDependencies.create))!;

    await tester.pumpWidget(
      d.provide(
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: const AppShell(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    const title = 'Faça um backup dos seus dados';
    expect(find.text(title), findsNothing);

    // peso adicionado
    d.progress.addWeight(70);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(title), findsOneWidget);

    // tocar leva à tela de backup
    await tester.tap(find.text(title));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Exportar backup'), findsOneWidget);
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // dispensar esconde; nova alteração mostra de novo
    await tester.tap(find.byTooltip('Dispensar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(title), findsNothing);

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    d.progress.addWeight(71);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(title), findsOneWidget);

    // exportar o backup resolve
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    d.backup.export();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(title), findsNothing);
  });
}
