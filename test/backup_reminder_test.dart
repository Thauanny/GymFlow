import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/data/equipment/equipment_catalog.dart';
import 'package:gymflow/state/app_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'primeira visita: escolher equipamentos e dias não pede backup',
    () async {
      SharedPreferences.setMockInitialValues({});
      final d = await AppDependencies.create();
      expect(d.backup.reminder.value, isFalse);

      d.equipment.setAll({for (final i in equipItems) i.id});
      d.equipment.save();
      d.planner.setDays({1, 3, 5});
      expect(d.backup.reminder.value, isFalse);
    },
  );

  test('com treino salvo e sem backup, o aviso aparece', () async {
    SharedPreferences.setMockInitialValues({});
    final d = await AppDependencies.create();
    d.equipment.setAll({for (final i in equipItems) i.id});
    d.equipment.save();
    d.planner.setDays({1, 3, 5});
    await d.planner.generateWeek();
    d.planner.commit(replaceDays: true);
    expect(d.backup.reminder.value, isTrue);
  });
}
