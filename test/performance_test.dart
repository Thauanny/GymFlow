import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/core/theme/app_theme.dart';
import 'package:gymflow/data/gif_catalog.dart';
import 'package:gymflow/state/app_dependencies.dart';
import 'package:gymflow/state/theme_cubit.dart';
import 'package:gymflow/ui/features/catalog/catalog_page.dart';
import 'package:gymflow/ui/features/equipment/equip_card.dart';
import 'package:gymflow/ui/features/equipment/equipment_page.dart';
import 'package:gymflow/ui/shell/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Garante as otimizações para celulares/Safari: só se monta o que aparece.
void main() {
  Future<AppDependencies> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final deps = (await tester.runAsync(AppDependencies.create))!;
    await tester.pumpWidget(
      deps.provide(
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          bloc: deps.theme,
          builder: (_, mode) => MaterialApp(
            theme: buildTheme(Brightness.light),
            home: const AppShell(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    return deps;
  }

  testWidgets('abas só são montadas na primeira visita', (tester) async {
    await open(tester);
    expect(find.byType(EquipmentPage, skipOffstage: false), findsNothing);
    expect(find.byType(CatalogPage, skipOffstage: false), findsNothing);

    await tester.tap(find.text('Academia').last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(EquipmentPage, skipOffstage: false), findsOneWidget);
    expect(find.byType(CatalogPage, skipOffstage: false), findsNothing);
  });

  testWidgets(
    'no celular as categorias da Academia começam fechadas e abrem ao toque',
    (tester) async {
      await open(tester);
      await tester.tap(find.text('Academia').last);
      await tester.pump(const Duration(milliseconds: 300));

      // fechadas: nenhum cartão (nenhum GIF) montado
      expect(find.byType(EquipCard), findsNothing);

      await tester.scrollUntilVisible(
        find.text('MÁQUINAS'),
        300,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .hitTestable()
            .first,
      );
      await tester.tap(find.text('MÁQUINAS'));
      await tester.pump(const Duration(milliseconds: 400));

      final built = find.byType(EquipCard).evaluate().length;
      expect(built, greaterThan(0));
      expect(built, lessThan(20), reason: '$built cartões montados de uma vez');
    },
  );

  test(
    'GIFs do celular usam a versão WebP animada (e o original como reserva)',
    () {
      final url = gifLiteUrl('https://static.exercisedb.dev/media/abc.gif');
      expect(url, startsWith('https://wsrv.nl/?url='));
      expect(
        url,
        contains(
          Uri.encodeComponent('https://static.exercisedb.dev/media/abc.gif'),
        ),
      );
      expect(url, contains('output=webp'));
      expect(url, contains('n=-1')); // mantém todos os quadros (animado)
    },
  );
}
