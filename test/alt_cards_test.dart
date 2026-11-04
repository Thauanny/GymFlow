import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/core/theme/app_theme.dart';
import 'package:gymflow/data/equipment/equipment_catalog.dart';
import 'package:gymflow/state/app_dependencies.dart';
import 'package:gymflow/ui/features/equipment/alt_card.dart';
import 'package:gymflow/ui/features/equipment/alternatives_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final size in [
    const Size(320, 700),
    const Size(390, 844),
    const Size(900, 800),
  ]) {
    testWidgets(
      'alternativas: cartões iguais e alinhados em ${size.width.toInt()}px',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({});
        final deps = (await tester.runAsync(AppDependencies.create))!;
        final item = equipItems.firstWhere((i) => i.id == 'm_smith');
        final exercise = deps.catalog.byId(item.imageId)!;

        await tester.pumpWidget(
          deps.provide(
            child: MaterialApp(
              theme: buildTheme(Brightness.light),
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => showAlternatives(context, item, exercise),
                    child: const Text('abrir'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('abrir'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        final cards = find.byType(AltCard).evaluate().toList();
        expect(cards.length, greaterThan(1));
        final sizes = [
          for (final c in cards) tester.getSize(find.byWidget(c.widget)),
        ];
        // largura e altura iguais em todos os cartões
        for (final s in sizes) {
          expect(
            s.height,
            closeTo(sizes.first.height, .5),
            reason: 'alturas diferentes',
          );
          expect(
            s.width,
            closeTo(sizes.first.width, .5),
            reason: 'larguras diferentes',
          );
        }
        // botões ocupam a largura do cartão (não ficam estreitos)
        final firstCard = tester.getRect(find.byWidget(cards.first.widget));
        final button = find.descendant(
          of: find.byWidget(cards.first.widget),
          matching: find.byType(OutlinedButton),
        );
        if (button.evaluate().isNotEmpty) {
          expect(
            tester.getSize(button.first).width,
            greaterThan(firstCard.width - 24),
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
