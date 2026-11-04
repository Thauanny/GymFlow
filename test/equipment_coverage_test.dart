import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/data/equipment/equipment_catalog.dart';
import 'package:gymflow/data/equipment/equipment_matcher.dart';
import 'package:gymflow/state/app_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppDependencies> deps() async {
    SharedPreferences.setMockInitialValues({});
    return AppDependencies.create();
  }

  test(
    'todo exercício (base + GIFs) pertence a um aparelho do catálogo',
    () async {
      final d = await deps();
      final orphans = d.catalog.state.exercises
          .where((e) => itemForExercise(e) == null)
          .toList();
      expect(
        orphans.map((e) => '${e.name} [${e.equipKey}]').toList(),
        isEmpty,
        reason: 'exercícios sem aparelho nunca seriam sugeridos',
      );
    },
  );

  test(
    'cada exercício está em um único aparelho e nenhum aparelho fica vazio',
    () async {
      final d = await deps();
      final all = d.catalog.state.exercises;
      final counts = {for (final it in equipItems) it.id: 0};
      for (final e in all) {
        final owners = equipItems.where((i) => itemMatches(i, e)).toList();
        expect(
          owners.length,
          1,
          reason: '${e.name}: ${owners.map((o) => o.id)}',
        );
        counts[owners.single.id] = counts[owners.single.id]! + 1;
      }
      final empty = [
        for (final e in counts.entries)
          if (e.value == 0) e.key,
      ];
      expect(empty, isEmpty);
    },
  );

  test('não existe categoria "Outros...": nomes dizem o que o aparelho é', () {
    for (final it in equipItems) {
      expect(it.rest, isFalse, reason: it.id);
      expect(
        RegExp(r'^(Outros?|Outras?|Demais)\b').hasMatch(it.label),
        isFalse,
        reason: it.label,
      );
    }
  });

  test(
    'com todos os equipamentos, todos os exercícios ficam disponíveis',
    () async {
      final d = await deps();
      d.equipment.setAll({for (final i in equipItems) i.id});
      expect(
        d.equipment.state.draftAvailable.length,
        d.catalog.state.exercises.length,
      );
    },
  );
}
