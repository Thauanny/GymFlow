import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/data/equipment/equipment_catalog.dart';
import 'package:gymflow/data/equipment/equipment_matcher.dart';

import 'support/exercise_fixtures.dart';

void main() {
  final all = loadExercises();

  test('todo exercício da base pertence a algum aparelho do catálogo', () {
    final orphans = all.where((e) => itemForExercise(e) == null).toList();
    expect(
      orphans.map((e) => '${e.name} [${e.equipKey}]').toList(),
      isEmpty,
      reason: 'exercícios sem aparelho nunca seriam sugeridos',
    );
  });

  test('só o item "resto" de halteres pode ficar vazio (a tela o esconde)', () {
    final empty = equipItems
        .where((i) => !all.any((e) => itemMatches(i, e)))
        .map((i) => i.id)
        .toList();
    expect(empty, ['d_free']);
  });

  test('com todos os equipamentos, todos os exercícios ficam disponíveis', () {
    final pool = poolFor({for (final i in equipItems) i.dbEquip});
    expect(pool.length, all.length);
  });
}
