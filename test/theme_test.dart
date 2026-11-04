import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/core/theme/app_palette.dart';
import 'package:gymflow/core/theme/app_theme.dart';

void main() {
  // Roda em modo debug (com asserts), como o `flutter run`.
  for (final b in Brightness.values) {
    test('tema ${b.name} é construído sem erros', () {
      final theme = buildTheme(b);
      expect(theme.brightness, b);
      expect(theme.extension<AppPalette>(), isNotNull);
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Barlow');
      expect(theme.textTheme.bodyMedium?.fontSize, isNotNull);
    });
  }

  testWidgets('app renderiza texto com o tema novo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: const Scaffold(body: Text('GymFlow')),
      ),
    );
    expect(find.text('GymFlow'), findsOneWidget);
  });
}
