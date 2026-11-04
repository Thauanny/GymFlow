import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/core/theme/app_theme.dart';
import 'package:gymflow/data/equipment/equipment_catalog.dart';
import 'package:gymflow/state/app_dependencies.dart';
import 'package:gymflow/ui/features/workouts/plan_sheets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('o aviso "Desfazer" some sozinho', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final d = (await tester.runAsync(() async {
      final d = await AppDependencies.create();
      d.equipment.setAll({for (final i in equipItems) i.id});
      d.equipment.save();
      d.planner.setDays({1, 3, 5});
      await d.planner.generateWeek();
      d.planner.commit(replaceDays: true);
      return d;
    }))!;

    await tester.pumpWidget(
      d.provide(
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showChangePlanSheet(context, day: 1),
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
    await tester.tap(find.text('TODOS OS DIAS'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Desfazer'), findsOneWidget);

    await tester.pump(const Duration(seconds: 9));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Desfazer'), findsNothing);
  });
}
