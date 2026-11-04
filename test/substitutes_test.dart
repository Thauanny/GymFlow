import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/data/equipment/equipment_catalog.dart';
import 'package:gymflow/domain/movement_patterns.dart';
import 'package:gymflow/domain/training/training_profile.dart';
import 'package:gymflow/domain/training/substitutes.dart';
import 'package:gymflow/state/app_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('famílias de movimento', () {
    expect(movementFamily('Cable Deadlifts'), 'hinge');
    expect(movementFamily('Romanian Deadlift'), 'hinge');
    expect(movementFamily('Barbell Bench Press - Medium Grip'), 'hpress');
    expect(movementFamily('Dumbbell Shoulder Press'), 'vpress');
    expect(movementFamily('Leg Press'), 'legpress');
    expect(movementFamily('Barbell Walking Lunge'), 'lunge');
  });

  test(
    'terra na polia pode virar terra com barra/halter (mesmo movimento)',
    () async {
      SharedPreferences.setMockInitialValues({});
      final d = await AppDependencies.create();
      d.equipment.setAll({for (final i in equipItems) i.id});
      d.equipment.save();
      final pool = d.equipment.state.available;
      final current = d.catalog.state.exercises.firstWhere(
        (e) => e.name == 'Cable Deadlifts',
      );
      final options = suggestSubstitutes(
        current: current,
        pool: pool,
        exclude: {},
        profile: const TrainingProfile(level: 'expert'),
        max: 6,
      );
      expect(options, isNotEmpty);
      // o primeiro da lista é do mesmo movimento (terra), em outro equipamento
      expect(
        movementFamily(options.first.name),
        'hinge',
        reason: '${options.map((e) => e.name)}',
      );
      expect(options.first.equipKey, isNot('cable'));
      expect(
        options.any(
          (e) => e.equipKey == 'barbell' && movementFamily(e.name) == 'hinge',
        ),
        isTrue,
        reason: '${options.map((e) => '${e.name}[${e.equipKey}]')}',
      );
    },
  );

  test(
    'agachamento: mostra a variação em máquina e prioriza o mesmo movimento',
    () async {
      SharedPreferences.setMockInitialValues({});
      final d = await AppDependencies.create();
      d.equipment.setAll({for (final i in equipItems) i.id});
      d.equipment.save();
      final current = d.catalog.state.exercises.firstWhere(
        (e) => e.name == 'Barbell Squat',
      );
      final options = suggestSubstitutes(
        current: current,
        pool: d.equipment.state.available,
        exclude: {},
        profile: const TrainingProfile(level: 'expert'),
      );
      final names = options.map((e) => '${e.name}[${e.equipKey}]').toList();
      expect(options.length, 8, reason: '$names');
      // os primeiros são todos agachamentos (mesmo movimento)
      expect(
        options.take(5).every((e) => movementFamily(e.name) == 'squat'),
        isTrue,
        reason: '$names',
      );
      // e há variação em máquina entre eles
      expect(
        options.any(
          (e) => e.equipKey == 'machine' && movementFamily(e.name) == 'squat',
        ),
        isTrue,
        reason: '$names',
      );
    },
  );

  test(
    'terra romeno: a lista completa inclui o terra com barra, sem corte',
    () async {
      SharedPreferences.setMockInitialValues({});
      final d = await AppDependencies.create();
      d.equipment.setAll({for (final i in equipItems) i.id});
      d.equipment.save();
      final current = d.catalog.state.exercises.firstWhere(
        (e) => e.name == 'Romanian Deadlift',
      );
      final o = substituteOptions(
        current: current,
        pool: d.equipment.state.available,
        exclude: {},
        profile: const TrainingProfile(level: 'expert'),
      );
      final names = o.sameMovement.map((e) => e.name).toList();
      expect(names, contains('Barbell Deadlift'), reason: '$names');
      // o equipamento do exercício atual (barra) vem primeiro
      expect(o.sameMovement.first.equipKey, 'barbell');
      // e há opções de vários equipamentos
      expect(
        o.sameMovement.map((e) => e.equipKey).toSet().length,
        greaterThan(3),
      );
    },
  );
}
