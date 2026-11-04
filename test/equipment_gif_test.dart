import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/data/equipment/equipment_catalog.dart';
import 'package:gymflow/data/equipment/equipment_gif.dart';
import 'package:gymflow/data/equipment/equipment_matcher.dart';
import 'package:gymflow/data/gif_catalog.dart';

import 'support/exercise_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(GifCatalog, List<dynamic>)> setup() async {
    final gifs = GifCatalog();
    await gifs.load();
    return (gifs, loadExercises());
  }

  test(
    'todo aparelho específico tem GIF; os genéricos ficam com o desenho',
    () async {
      final (gifs, exercises) = await setup();
      final none = [
        for (final it in equipItems)
          if (!it.rest &&
              exercises.any((e) => itemMatches(it, e)) &&
              gifsForItem(it, gifs, exercises.cast()).isEmpty)
            it.id,
      ];
      expect(none, isEmpty, reason: 'ficariam só com o desenho: $none');
    },
  );

  test('dois aparelhos nunca mostram o mesmo GIF', () async {
    final (gifs, exercises) = await setup();
    final byGif = <String, List<String>>{};
    for (final it in equipItems) {
      final list = gifsForItem(it, gifs, exercises.cast());
      if (list.isNotEmpty) byGif.putIfAbsent(list.first, () => []).add(it.id);
    }
    final repeated = {
      for (final e in byGif.entries)
        if (e.value.length > 1) e.key: e.value,
    };
    expect(repeated, isEmpty, reason: 'GIFs repetidos entre aparelhos');
  });

  test('todo aparelho do catálogo tem GIF próprio', () async {
    final (gifs, exercises) = await setup();
    for (final it in equipItems.where((i) => !i.rest)) {
      if (!exercises.any((e) => itemMatches(it, e))) continue;
      expect(gifs.itemGif(it.id), isNotNull, reason: it.id);
    }
  });
}
