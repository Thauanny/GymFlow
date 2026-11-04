import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/core/theme/app_theme.dart';
import 'package:gymflow/data/translation/pt_names.dart';
import 'package:gymflow/state/app_dependencies.dart';
import 'package:gymflow/ui/features/exercise/exercise_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final size in [const Size(320, 640), const Size(390, 844)]) {
    testWidgets('detalhe do exercício em ${size.width.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final deps = (await tester.runAsync(AppDependencies.create))!;
      final e = deps.catalog.byId('Smith_Machine_Squat')!;

      await tester.pumpWidget(
        deps.provide(
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showExercise(context, e),
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

      // nome em português; nenhuma instrução em inglês
      expect(find.text(exerciseNamePt(e.name).toUpperCase()), findsOneWidget);
      expect(
        find.textContaining(e.instructions.first.substring(0, 20)),
        findsNothing,
      );

      // legendas das abas em uma linha só (não quebram a palavra)
      for (final label in ['Animação', 'Desenho']) {
        final h = tester.getSize(find.text(label)).height;
        expect(
          h,
          lessThan(20),
          reason: '"$label" quebrou em mais de uma linha',
        );
      }

      // botão de fechar com área de toque confortável
      final close = tester.getSize(find.byTooltip('Fechar'));
      expect(close.width, greaterThanOrEqualTo(44));
      expect(close.height, greaterThanOrEqualTo(44));

      // resumo em português
      expect(find.text('TRABALHA'), findsOneWidget);
      expect(find.text('Quadríceps'), findsWidgets);

      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Fechar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byTooltip('Fechar'), findsNothing);
    });
  }
}
