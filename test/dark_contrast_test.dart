import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/core/theme/app_theme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + .05) / (lo + .05);
}

void main() {
  for (final mode in Brightness.values) {
    testWidgets('chip selecionado legível (${mode.name})', (tester) async {
      late BuildContext inner, iconCtx;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(mode),
          home: Scaffold(
            body: Builder(
              builder: (c) {
                inner = c;
                return Column(
                  children: [
                    ChoiceChip(
                      avatar: Builder(
                        builder: (c) {
                          iconCtx = c;
                          return const Icon(Icons.bolt);
                        },
                      ),
                      label: const Text('Selecionado'),
                      selected: true,
                      onSelected: (_) {},
                    ),
                    FilledButton.tonal(
                      onPressed: () {},
                      child: const Text('tonal'),
                    ),
                    IconButton.filledTonal(
                      onPressed: () {},
                      icon: const Icon(Icons.close, key: Key('tonalIcon')),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      final bg = Theme.of(inner).chipTheme.selectedColor!;
      final label = tester.widget<RichText>(
        find.descendant(
          of: find.byType(ChoiceChip),
          matching: find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText() == 'Selecionado',
          ),
        ),
      );
      expect(_contrast(label.text.style!.color!, bg), greaterThan(4.5));
      final icon = IconTheme.of(iconCtx).color!;
      expect(_contrast(icon, bg), greaterThan(4.5), reason: 'ícone do chip');

      final tonalBg = Theme.of(inner).colorScheme.secondaryContainer;
      final tonalIcon = tester.widget<Icon>(find.byKey(const Key('tonalIcon')));
      final iconColor = IconTheme.of(
        tester.element(find.byKey(const Key('tonalIcon'))),
      ).color!;
      expect(tonalIcon, isNotNull);
      expect(
        _contrast(iconColor, tonalBg),
        greaterThan(4.5),
        reason: 'IconButton.filledTonal',
      );
    });
  }
}
