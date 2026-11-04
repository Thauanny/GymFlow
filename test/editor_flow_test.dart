import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/core/theme/app_theme.dart';
import 'package:gymflow/data/equipment/equipment_catalog.dart';
import 'package:gymflow/state/app_dependencies.dart';
import 'package:gymflow/ui/features/workouts/workout_editor_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('montar treino à mão: exercício + alongamento, e salvar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final d = (await tester.runAsync(() async {
      final d = await AppDependencies.create();
      d.equipment.setAll({for (final i in equipItems) i.id});
      d.equipment.save();
      return d;
    }))!;

    await tester.pumpWidget(
      d.provide(
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: const WorkoutEditorPage(focusId: 'legs', weekday: 2),
        ),
      ),
    );
    await tester.pump();

    // alongamento (primeira seção)
    await tester.tap(find.text('Adicionar').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byType(ListTile).first);
    await tester.pump();
    await tester.tap(find.textContaining('Concluir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('ALONGAMENTOS (1)'), findsOneWidget);

    // exercício
    await tester.tap(find.text('Adicionar').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byType(ListTile).first);
    await tester.pump();
    await tester.tap(find.textContaining('Concluir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('EXERCÍCIOS (1)'), findsOneWidget);

    await tester.tap(find.text('Salvar treino'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    final w = d.workouts.state.workouts.single;
    expect(w.items, hasLength(1));
    expect(w.stretches, hasLength(1));
    expect(
      d.catalog.byId(w.stretches.single.exerciseId)!.category,
      'stretching',
    );
    expect(
      d.catalog.byId(w.items.single.exerciseId)!.category,
      isNot('stretching'),
    );
  });
}
