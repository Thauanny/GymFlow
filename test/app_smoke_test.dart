import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/core/theme/app_theme.dart';
import 'package:gymflow/data/equipment/equipment_catalog.dart';
import 'package:gymflow/state/app_dependencies.dart';
import 'package:gymflow/state/theme_cubit.dart';
import 'package:gymflow/ui/shell/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sobe o app inteiro em modo debug (com asserts, que acusam overflow) e passa
/// por todas as telas, do celular pequeno ao desktop.
const _sizes = [
  Size(320, 700),
  Size(360, 740),
  Size(420, 900),
  Size(800, 900),
  Size(980, 800),
  Size(1280, 900),
];

Future<void> _scrollThrough(WidgetTester t) async {
  final lists = find
      .byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      )
      .hitTestable();
  if (lists.evaluate().isEmpty) return;
  for (var i = 0; i < 14; i++) {
    await t.drag(lists.first, const Offset(0, -1200));
    await t.pump(const Duration(milliseconds: 80));
  }
}

/// Locais (arquivo:linha em lib/) onde houve erro de layout, sem repetição.
final _problems = <String>{};
final _seenStacks = <String>{};
var _reports = 0;

/// Coleta erros de forma barata: o mesmo erro se repete a cada quadro e montar
/// o texto completo é caro, então só detalhamos pilhas ainda não vistas.
void _collect(FlutterErrorDetails d) {
  // cada widget com overflow reporta a cada quadro; só os primeiros bastam
  if (++_reports > 120) return;
  // Nos testes toda requisição HTTP volta 400: GIFs que não carregam não são
  // problema de layout (o app mostra um ícone de reserva).
  if (d.exceptionAsString().contains('HTTP request failed')) return;
  final text = d.toString();
  final where =
      RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(text)?.group(0) ?? '?';
  final what = text.contains('overflowed')
      ? 'overflow'
      : 'erro (${d.exceptionAsString().split('\n').first})';
  _problems.add('$what em $where');
}

/// Esvazia a exceção pendente do teste (os detalhes já foram coletados).
void _noErrors(WidgetTester t, String where) => t.takeException();

/// Deixa animações (menu, rotas, modais) terminarem. Não dá para usar
/// pumpAndSettle: a tela tem indicadores e GIFs que nunca "assentam".
Future<void> _pumpUi(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 500));
  await t.pump(const Duration(milliseconds: 500));
}

/// Toca numa aba: em tela larga ela fica no topo (antes do conteúdo na árvore),
/// no celular fica embaixo (depois do conteúdo).
Future<void> _tapTab(WidgetTester t, String label, double width) async {
  final f = find.text(label);
  await t.tap(width >= 960 ? f.first : f.last);
  await t.pump(const Duration(milliseconds: 300));
}

void main() {
  for (final size in _sizes) {
    testWidgets('sem overflow em ${size.width.toInt()}px', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      _problems.clear();
      _seenStacks.clear();
      _reports = 0;
      final original = FlutterError.onError;
      FlutterError.onError = _collect;
      addTearDown(() => FlutterError.onError = original);
      try {
        final deps = (await tester.runAsync(AppDependencies.create))!;
        // academia completa e um plano gerado (rascunho), para ter conteúdo real
        deps.equipment.setAll({for (final i in equipItems) i.id});
        deps.equipment.save();
        deps.planner.setDays({1, 2, 3, 4});
        await tester.runAsync(deps.planner.generateWeek);

        await tester.pumpWidget(
          deps.provide(
            child: BlocBuilder<ThemeCubit, ThemeMode>(
              bloc: deps.theme,
              builder: (_, mode) => MaterialApp(
                theme: buildTheme(Brightness.light),
                darkTheme: buildTheme(Brightness.dark),
                themeMode: mode,
                home: const AppShell(),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        _noErrors(tester, 'início');

        // planejador com a semana gerada
        await _tapTab(tester, 'Treinos', size.width);
        await tester.tap(find.text('Montar plano'));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));
        await _scrollThrough(tester);
        _noErrors(tester, 'planejador');
        Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
        await tester.pump(const Duration(milliseconds: 500));

        // salva o plano e percorre as demais telas, com treinos reais
        deps.planner.commit(replaceDays: true);
        await tester.pump(const Duration(milliseconds: 300));

        for (final label in [
          'Treinos',
          'Academia',
          'Explorar',
          'Progresso',
          'Início',
        ]) {
          await _tapTab(tester, label, size.width);
          _noErrors(tester, 'aba $label');
          await _scrollThrough(tester);
          _noErrors(tester, 'aba $label (rolada)');
        }

        // menu sanduíche: configurações (aparência + backup) e contato
        await tester.tap(find.byTooltip('Menu'));
        await _pumpUi(tester);
        await tester.tap(find.text('Configurações'));
        await _pumpUi(tester);
        await _scrollThrough(tester);
        _noErrors(tester, 'configurações');
        // a lista é preguiçosa: volta a rolar para cima até o card de backup
        await tester.scrollUntilVisible(
          find.text('Exportar backup'),
          -300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Exportar backup'), findsOneWidget);
        await tester.pageBack();
        await _pumpUi(tester);

        await tester.tap(find.byTooltip('Menu'));
        await _pumpUi(tester);
        await tester.tap(find.text('Contato e sugestões'));
        await _pumpUi(tester);
        expect(find.text('Abrir LinkedIn'), findsOneWidget);
        expect(find.text('Thauanny Ramos'), findsOneWidget);
        _noErrors(tester, 'contato');
        await tester.tapAt(const Offset(4, 4)); // fecha o modal
        await _pumpUi(tester);

        // ficha do treino
        await _tapTab(tester, 'Treinos', size.width);
        final start = find.text('Começar').hitTestable();
        if (start.evaluate().isNotEmpty) {
          await tester.tap(start.first);
          await tester.pump(const Duration(milliseconds: 500));
          await _scrollThrough(tester);
          _noErrors(tester, 'ficha do treino');
        }

        FlutterError.onError = original;
        expect(
          _problems.toList()..sort(),
          isEmpty,
          reason: 'problemas de layout em ${size.width.toInt()}px',
        );
      } catch (_) {
        // devolve o tratador original para o erro real aparecer no relatório
        FlutterError.onError = original;
        rethrow;
      }
    });
  }
}
