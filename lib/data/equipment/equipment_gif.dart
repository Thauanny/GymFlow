import '../../models/exercise.dart';
import '../gif_catalog.dart';
import 'equipment_catalog.dart';
import 'equipment_matcher.dart';

/// GIFs candidatos de um aparelho, do mais ao menos específico: o do próprio
/// aparelho, o do exercício que o representa e o de outros exercícios feitos
/// nele. A tela tenta um por vez (alguns links podem estar fora do ar).
List<String> gifsForItem(
  EquipItem item,
  GifCatalog gifs,
  List<Exercise> exercises, {
  int max = 3,
}) {
  final out = <String>[];
  void add(String? url) {
    if (url != null && !out.contains(url) && out.length < max) out.add(url);
  }

  add(gifs.itemGif(item.id));
  // Itens genéricos ("outros...") não têm um movimento só: ficam com o desenho.
  if (item.rest) return out;
  for (final e in exercises) {
    if (e.id == item.imageId) add(gifs.gifFor(e));
  }
  for (final e in exercises) {
    if (out.length >= max) break;
    if (itemMatches(item, e)) add(gifs.gifFor(e));
  }
  return out;
}
