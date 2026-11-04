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
  final List<String> _keys = [];
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
        _keys.add(e.key);
      }
    } catch (_) {
      // Sem GIFs o app continua funcionando com ilustrações.
    }
  }

  String? itemGif(String itemId) {
    final id = _itemGifs[itemId];
    return id == null ? null : '$gifBase$id.gif';
  }

  /// GIF correspondente ao exercício (similaridade de nome). É conservador:
  /// sem um par confiável devolve null (a tela usa o desenho do aparelho),
  /// em vez de mostrar o movimento de outro exercício.
  String? gifFor(Exercise e) => _cache.putIfAbsent(
    e.id,
    () => _bestGif(
      e.name,
      e.equipKey,
      // Alongamentos têm nomes parecidos entre si: só pareia quase igual.
      min: e.category == 'stretching' ? .8 : .5,
    ),
  );

  String? _bestGif(String name, String equipKey, {double min = .5}) {
    final t = nameTokens(name);
    var best = 0.0;
    String? id;
    for (var i = 0; i < _tokens.length; i++) {
      final (tk, gid) = _tokens[i];
      final inter = t.intersection(tk).length;
      if (inter == 0) continue;
      if (!_compatible(equipKey, _keys[i], t, tk)) continue;
      final score = inter / (t.length + tk.length - inter);
      if (score > best) {
        best = score;
        id = gid;
      }
    }
    return best >= min ? '$gifBase$id.gif' : null;
  }

  /// Equipamento do GIF bate com o do exercício, as palavras que mudam o
  /// movimento (stiff, sumô, inclinado...) aparecem nos dois lados e um nome
  /// contém o outro (ignorando o equipamento).
  static bool _compatible(
    String equipKey,
    String gifKey,
    Set<String> a,
    Set<String> b,
  ) {
    final prefix = gifKey.split(' ').first;
    final allowed = _prefixEquip[prefix];
    if (allowed != null && !allowed.contains(equipKey)) return false;
    if (a.difference(b).union(b.difference(a)).any(_movementWords.contains)) {
      return false;
    }
    final x = a.difference(_equipWords), y = b.difference(_equipWords);
    return x.containsAll(y) || y.containsAll(x);
  }

  static const _prefixEquip = <String, Set<String>>{
    'dumbbell': {'dumbbell'},
    'barbell': {'barbell'},
    'cable': {'cable'},
    'machine': {'machine'},
    'band': {'bands'},
    'smith': {'barbell', 'machine'},
    'kettlebell': {'kettlebells'},
    'ez-bar': {'e-z curl bar'},
    'medicine': {'medicine ball'},
    'exercise': {'exercise ball'},
    'sled': {'machine'},
  };

  static const _equipWords = <String>{
    'dumbbell',
    'barbell',
    'cable',
    'band',
    'smith',
    'kettlebell',
    'ez',
    'bar',
    'medicine',
    'ball',
    'weighted',
    'assisted',
    'bodyweight',
  };

  static const _movementWords = <String>{
    'stiff',
    'sumo',
    'romanian',
    'incline',
    'decline',
    'reverse',
    'wide',
    'close',
    'narrow',
    'behind',
    'seated',
    'standing',
    'lying',
    'kneeling',
    'single',
    'alternate',
    'hammer',
    'preacher',
    'bent',
    'jump',
    'front',
    'rear',
    'lateral',
    'stretch',
    'squat',
    'curl',
    'press',
    'row',
    'raise',
    'extension',
    'deadlift',
    'lunge',
    'fly',
    'crunch',
    'pulldown',
    'pullup',
    'pull',
    'push',
    'kickback',
    'thrust',
    'shrug',
    'twist',
    'dip',
    'plank',
    'bridge',
    'calf',
    'leg',
    'hip',
    'good',
    'morning',
    'goblet',
    'hack',
    'zercher',
    'sissy',
    'pistol',
    'step',
    'split',
    'inner',
    'outer',
    'upper',
    'lower',
    'high',
    'low',
    'pause',
    'overhead',
  };
}
