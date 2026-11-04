import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/core/theme/app_theme.dart';
import 'package:gymflow/data/equipment/equipment_catalog.dart';
import 'package:gymflow/models/day_focus.dart';
import 'package:gymflow/state/app_dependencies.dart';
import 'package:gymflow/ui/features/workouts/exercise_picker_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final stretch in [false, true]) {
    testWidgets('seletor estrito (${stretch ? 'alongamentos' : 'exercícios'}) '
        'só mostra o foco do dia', (tester) async {
      tester.view.physicalSize = const Size(430, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final d = (await tester.runAsync(() async {
        final d = await AppDependencies.create();
        d.equipment.setAll({for (final i in equipItems) i.id});
        d.equipment.save();
        return d;
      }))!;
      final focus = dayFocuses['legs']!;
      await tester.pumpWidget(
        d.provide(
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: Scaffold(
              body: ExercisePickerSheet(
                focus: focus,
                stretch: stretch,
                strict: true,
                chosen: <String>{},
                onToggle: (_, _) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      // sem o botão de ampliar para fora do foco
      expect(find.textContaining('Só pernas'), findsNothing);
      expect(find.textContaining('Peito'), findsNothing);
      expect(find.textContaining('Bíceps'), findsNothing);
      expect(
        find.text(
          '${stretch ? 'Alongamentos' : 'Exercícios'} · ${focus.label}',
        ),
        findsOneWidget,
      );
      // todo item listado é de um músculo das pernas
      const legs = [
        'Quadríceps',
        'Posterior de coxa',
        'Glúteos',
        'Panturrilha',
        'Abdutores',
        'Adutores',
      ];
      final subs = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .map((t) => (t.subtitle as Text).data!)
          .toList();
      expect(subs, isNotEmpty);
      for (final s in subs) {
        expect(legs.any(s.contains), isTrue, reason: s);
      }
    });
  }
}
