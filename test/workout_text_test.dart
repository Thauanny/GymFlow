import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/data/equipment/equipment_catalog.dart';
import 'package:gymflow/data/translation/pt_names.dart';
import 'package:gymflow/domain/training/workout_text.dart';
import 'package:gymflow/state/app_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a ficha vira um texto bem formatado para o WhatsApp', () async {
    SharedPreferences.setMockInitialValues({});
    final d = await AppDependencies.create();
    d.equipment.setAll({for (final i in equipItems) i.id});
    d.equipment.save();
    d.planner.setDays({1, 3});
    d.planner.setFocus(1, 'chest_triceps');
    await d.planner.generateWeek();
    final w = d.planner.state.drafts[1]!.workout;
    w.items.first.kg = 40;

    final text = workoutToText(w, byId: d.catalog.byId, namePt: exerciseNamePt);
    // ignore: avoid_print
    print('FICHA>>>\n$text\n<<<');
    expect(text, startsWith('*SEGUNDA · PEITO E TRÍCEPS*'));
    expect(text, contains('*ALONGAMENTOS*'));
    expect(text, contains('*EXERCÍCIOS*'));
    // sem emojis: pelo wa.me o WhatsApp os mostra como "�"
    expect(text.runes.any((r) => r > 0xFFFF), isFalse);
    expect(text.contains('\uFE0F'), isFalse);
    // alongamentos vêm antes dos exercícios
    expect(text.indexOf('ALONGAMENTOS'), lessThan(text.indexOf('EXERCÍCIOS')));
    expect(text, contains('1. *'));
    expect(text, contains('40 kg'));
    expect(text, contains('descanso'));
    expect(text, endsWith(appLink));

    final week = weekToText(
      d.planner.state.drafts.values.map((e) => e.workout).toList(),
      byId: d.catalog.byId,
      namePt: exerciseNamePt,
    );
    expect(week, contains('MINHA SEMANA DE TREINO'));
    expect(week.indexOf('SEGUNDA'), lessThan(week.indexOf('QUARTA')));
    expect('Montado no GymFlow'.allMatches(week).length, 1);
  });
}
