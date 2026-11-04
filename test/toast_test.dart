import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/core/theme/app_palette.dart';
import 'package:gymflow/core/theme/app_theme.dart';
import 'package:gymflow/ui/widgets/toast.dart';

void main() {
  for (final b in Brightness.values) {
    testWidgets(
      'aviso usa as cores do tema (${b.name}), nunca o vermelho padrão',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildTheme(b),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showToast(context, 'Plano gerado!'),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('abrir'));
        await tester.pump(const Duration(milliseconds: 400));

        final style = tester.widget<Text>(find.text('Plano gerado!')).style!;
        final palette = b == Brightness.dark
            ? AppPalette.dark
            : AppPalette.light;
        expect(style.color, palette.text);
        expect(style.decoration, TextDecoration.none);
        // o Material transparente garante o estilo de texto do tema
        final inherited = DefaultTextStyle.of(
          tester.element(find.text('Plano gerado!')),
        ).style;
        expect(inherited.color, isNot(const Color(0xD0FF0000)));
        expect(inherited.decoration, isNot(TextDecoration.underline));

        await tester.pump(const Duration(seconds: 4)); // deixa o aviso sumir
      },
    );
  }
}
