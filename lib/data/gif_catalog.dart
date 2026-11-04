import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../core/utils/text_tokens.dart';
import '../models/exercise.dart';
import 'alt.dart';
import '../models/labels.dart';

const gifBase = 'https://static.exercisedb.dev/media/';

/// Versão WebP animada do mesmo GIF (mesma resolução e quadros, ~4x menor),
/// gerada por um serviço de imagens. Usada nas listas do celular.
String gifLiteUrl(String gif) =>
    'https://wsrv.nl/?url=${Uri.encodeComponent(gif)}&n=-1&output=webp&q=50';

/// Primeiro quadro do GIF, já reduzido para [px] (poucos KB, sem animação).
String gifThumbUrl(String gif, int px) =>
    'https://wsrv.nl/?url=${Uri.encodeComponent(gif)}&w=$px&h=$px&fit=contain&output=webp&q=60';

/// GIFs instrutivos: por exercício, por aparelho e as variações por equipamento.
class GifCatalog {
  final Map<String, String> _byName = {};
  final Map<String, String> _itemGifs = {};
  final List<(Set<String>, String)> _tokens = [];
  final Map<String, String?> _cache = {};
  final List<Alt> alts = [];

  Future<dynamic> _read(String path) async =>
      jsonDecode(await rootBundle.loadString('assets/gif/$path.json'));

  Future<void> load() async {
    try {
      _byName.addAll(Map<String, String>.from(await _read('exercises')));
      final items = await _read('items') as Map<String, dynamic>;
      for (final group in items.values) {
        _itemGifs.addAll(Map<String, String>.from(group as Map));
      }
      for (final equip in equipmentLabels.keys) {
        final list = await _read('alts/${equip.replaceAll(' ', '_')}') as List;
        for (final a in list) {
          alts.add(
            Alt(a[0] as String, '$gifBase${a[1]}.gif', equip, a[2] as String),
          );
        }
      }
      for (final e in _byName.entries) {
        _tokens.add((nameTokens(e.key), e.value));
      }
    } catch (_) {
      // Sem GIFs o app continua funcionando com ilustrações.
    }
  }

  String? itemGif(String itemId) {
    final id = _itemGifs[itemId];
    return id == null ? null : '$gifBase$id.gif';
  }

  /// GIF correspondente ao exercício (similaridade de nome).
  String? gifFor(Exercise e) =>
      _cache.putIfAbsent(e.id, () => _bestGif(nameTokens(e.name)));

  String? _bestGif(Set<String> t) {
    var best = 0.0;
    String? id;
    for (final (tk, gid) in _tokens) {
      final inter = t.intersection(tk).length;
      if (inter == 0) continue;
      final score = inter / (t.length + tk.length - inter);
      if (score > best) {
        best = score;
        id = gid;
      }
    }
    return best >= .5 ? '$gifBase$id.gif' : null;
  }
}
