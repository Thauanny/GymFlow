import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/core/theme/app_theme.dart';
import 'package:gymflow/data/equipment/equipment_catalog.dart';
import 'package:gymflow/state/app_dependencies.dart';
import 'package:gymflow/state/theme_cubit.dart';
import 'package:gymflow/models/day_focus.dart';
import 'package:gymflow/ui/features/exercise/exercise_dialog.dart';
import 'package:gymflow/ui/features/planner/planner_page.dart';
import 'package:gymflow/ui/features/settings/contact_sheet.dart';
import 'package:gymflow/ui/features/settings/settings_page.dart';
import 'package:gymflow/ui/features/workouts/exercise_picker_sheet.dart';
import 'package:gymflow/ui/features/workouts/plan_sheets.dart';
import 'package:gymflow/ui/features/workouts/workout_editor_page.dart';
import 'package:gymflow/ui/features/workouts/workout_ticket_page.dart';
import 'package:gymflow/ui/shell/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + .05) / (lo + .05);
}

/// Cor de fundo efetiva atrás de [e]: junta as camadas translúcidas até achar
/// uma opaca.
Color _backdrop(Element e, Color fallback) {
  final layers = <Color>[];
  e.visitAncestorElements((a) {
    final w = a.widget;
    Color? c;
    if (w is DecoratedBox && w.decoration is BoxDecoration) {
      c = (w.decoration as BoxDecoration).color;
    } else if (w is ColoredBox) {
      c = w.color;
    } else if (w is Material && w.type != MaterialType.transparency) {
      c = w.color ?? Theme.of(a).colorScheme.surface;
    }
    if (c != null && c.a > 0) {
      layers.add(c);
      if (c.a >= .99) return false;
    }
    return true;
  });
  var out = layers.isNotEmpty && layers.last.a >= .99 ? layers.last : fallback;
  for (final c in layers.reversed.skip(layers.last.a >= .99 ? 1 : 0)) {
    out = Color.alphaBlend(c, out);
  }
  return out;
}

final _found = <String>{};

void _audit(WidgetTester t, String where, Color bg) {
  for (final el in find.byType(RichText).evaluate()) {
    final w = el.widget as RichText;
    final text = w.text.toPlainText().trim();
    final color = w.text.style?.color;
    if (text.isEmpty || color == null || color.a < .5) continue;
    // Texto escuro sobre o lima de marca: chips e abas pintam o fundo por
    // fora de DecoratedBox/Material, então o fundo não é detectável aqui.
    if (color.toARGB32() & 0xFFFFFF == 0x0B0B0C) continue;
    final b = _backdrop(el, bg);
    final c = _contrast(Color.alphaBlend(color, b), b);
    if (c < 3) {
      _found.add(
        '$where: "${text.length > 30 ? text.substring(0, 30) : text}" '
        'contraste ${c.toStringAsFixed(2)} fg=${color.toARGB32().toRadixString(16)} bg=${b.toARGB32().toRadixString(16)} ${text.runes.map((r) => r.toRadixString(16)).take(1).join()}',
      );
    }
  }
}

void main() {
  testWidgets('modo escuro: textos legíveis nas telas principais', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'theme': 'dark'});
    final deps = (await tester.runAsync(AppDependencies.create))!;
    deps.equipment.setAll({for (final i in equipItems) i.id});
    deps.equipment.save();
    deps.planner.setDays({1, 2, 3});
    await tester.runAsync(deps.planner.generateWeek);
    deps.planner.commit(replaceDays: true);

    await tester.pumpWidget(
      deps.provide(
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          bloc: deps.theme,
          builder: (_, mode) => MaterialApp(
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: ThemeMode.dark,
            home: const AppShell(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    const bg = Color(0xFF0B0B0C);
    _audit(tester, 'Início', bg);
    for (final label in ['Treinos', 'Academia', 'Explorar', 'Progresso']) {
      await tester.tap(find.text(label).last);
      await tester.pump(const Duration(milliseconds: 500));
      _audit(tester, label, bg);
      // rola um pouco para ver mais
      final list = find.byType(Scrollable).hitTestable();
      if (list.evaluate().isNotEmpty) {
        await tester.drag(list.first, const Offset(0, -700));
        await tester.pump(const Duration(milliseconds: 200));
        _audit(tester, '$label (rolada)', bg);
      }
    }
    await tester.tap(find.text('Treinos').last);
    await tester.pump(const Duration(milliseconds: 400));

    Future<void> visit(String name, Widget page) async {
      final nav = Navigator.of(tester.element(find.byType(Scaffold).first));
      nav.push(MaterialPageRoute<void>(builder: (_) => page));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      _audit(tester, name, bg);
      final list = find.byType(Scrollable).hitTestable();
      if (list.evaluate().isNotEmpty) {
        await tester.drag(list.first, const Offset(0, -900));
        await tester.pump(const Duration(milliseconds: 200));
        _audit(tester, '$name (rolada)', bg);
      }
      nav.pop();
      await tester.pump(const Duration(milliseconds: 500));
    }

    final w = deps.workouts.state.workouts.first;
    await visit('Ficha do treino', WorkoutTicketPage(workout: w));
    await visit('Editor', WorkoutEditorPage(existing: w));
    await visit('Configurações', const SettingsPage());

    await visit('Planejador', const PlannerPage());
    final ctx = tester.element(find.byType(Scaffold).first);
    Future<void> overlay(String name, Future<void> Function() open) async {
      unawaited(open());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      _audit(tester, name, bg);
      Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
      await tester.pump(const Duration(milliseconds: 500));
    }

    await overlay('Contato', () => showContactSheet(ctx));
    await overlay('Trocar plano', () => showChangePlanSheet(ctx, day: 1));
    await overlay(
      'Seletor',
      () => showModalBottomSheet<void>(
        context: ctx,
        isScrollControlled: true,
        builder: (_) => ExercisePickerSheet(
          focus: focusById('legs'),
          chosen: <String>{},
          onToggle: (_, _) {},
        ),
      ),
    );
    final ex = deps.catalog.byId(w.items.first.exerciseId)!;
    showExercise(ctx, ex);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    _audit(tester, 'Detalhe do exercício', bg);

    // ignore: avoid_print
    print('PROBLEMAS (${_found.length}):\n${_found.join('\n')}');
    expect(_found, isEmpty);
  });
}
