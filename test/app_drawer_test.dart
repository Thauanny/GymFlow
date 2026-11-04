import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/core/app_version.dart';
import 'package:gymflow/core/theme/app_theme.dart';
import 'package:gymflow/ui/shell/app_drawer.dart';

double _contrast(Color a, Color b) {
  final l1 = a.computeLuminance(), l2 = b.computeLuminance();
  final hi = l1 > l2 ? l1 : l2, lo = l1 > l2 ? l2 : l1;
  return (hi + .05) / (lo + .05);
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('versão aparece no fim do menu (${brightness.name})', (
      tester,
    ) async {
      final key = GlobalKey<ScaffoldState>();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(brightness),
          home: Scaffold(
            key: key,
            endDrawer: const AppDrawer(),
            body: const SizedBox.expand(),
          ),
        ),
      );
      key.currentState!.openEndDrawer();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final finder = find.text('v$appVersion');
      expect(finder, findsOneWidget);

      // legível sobre o fundo do menu
      final text = tester.widget<Text>(finder);
      final drawerBg = tester
          .widget<Drawer>(find.byType(Drawer))
          .backgroundColor!;
      expect(_contrast(text.style!.color!, drawerBg), greaterThanOrEqualTo(3));

      // fica na parte de baixo do menu
      final drawer = tester.getRect(find.byType(Drawer));
      expect(tester.getRect(finder).bottom, greaterThan(drawer.bottom - 60));
    });
  }
}
