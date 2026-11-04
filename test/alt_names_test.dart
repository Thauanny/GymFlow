import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/data/alternatives_service.dart';
import 'package:gymflow/data/gif_catalog.dart';
import 'package:gymflow/data/translation/pt_alt_names.dart';

import 'support/exercise_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'todas as alternativas têm nome em português (sem inglês solto)',
    () async {
      final gifs = GifCatalog();
      await gifs.load();
      final exercises = loadExercises();
      final service = AlternativesService(gifs, () => exercises);

      final english = RegExp(
        r'\b(dumbbell|barbell|cable|bodyweight|stability ball|exercise ball|with|the)\b',
        caseSensitive: false,
      );
      // nomes de movimentos que ficam como são (termos usados em português)
      const keep = {'stalder press', 'power clean', 'skin the cat'};
      final bad = <String>[];
      for (final a in gifs.alts) {
        if (keep.contains(a.name.toLowerCase())) continue;
        final pt = service.altNamePt(a);
        if (pt.toLowerCase() == a.name.toLowerCase() || english.hasMatch(pt)) {
          bad.add('${a.name} -> $pt');
        }
      }
      expect(
        bad,
        isEmpty,
        reason: '${bad.length} sem tradução: ${bad.take(8)}',
      );
    },
  );

  test('a tabela própria não tem entradas vazias', () {
    for (final e in ptAltNames.entries) {
      expect(e.value, isNotEmpty);
    }
    expect(ptAltNames.length, greaterThan(900));
  });
}
