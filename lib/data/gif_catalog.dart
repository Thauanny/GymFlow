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
        _tokens.add((_gifWords(e.key), e.value));
        _keys.add(e.key);
      }
    } catch (_) {
      // Sem GIFs o app continua funcionando com ilustrações.
    }
  }

  /// Nome (em inglês) do exercício a que pertence um GIF (para conferência).
  String? nameOf(String url) {
    final id = url.split('/').last.replaceAll('.gif', '');
    for (final e in _byName.entries) {
      if (e.value == id) return e.key;
    }
    return null;
  }

  /// Fixa o GIF de um exercício que veio do próprio índice de GIFs.
  void bind(String exerciseId, String url) => _cache[exerciseId] = url;

  String? itemGif(String itemId) {
    final id = _itemGifs[itemId];
    return id == null ? null : '$gifBase$id.gif';
  }

  /// GIF correspondente ao exercício. Só aceita o GIF de **mesmo nome**: as
  /// mesmas palavras (ignorando ordem, plural e preposições), contando também o
  /// equipamento. Qualquer palavra a mais ou a menos (inclinado, sentado,
  /// unilateral, com elástico...) é outro exercício. Sem par exato devolve null
  /// e a tela usa as fotos da pessoa (e só depois o desenho).
  String? gifFor(Exercise e) => _cache.putIfAbsent(e.id, () => _exactGif(e));

  String? _exactGif(Exercise e) {
    final alias = _aliases[e.name.toLowerCase()];
    final aliasId = alias == null ? null : _byName[alias];
    if (aliasId != null) return '$gifBase$aliasId.gif';
    final t = {..._gifWords(e.name), ...?_equipWord[e.equipKey]};
    for (var i = 0; i < _tokens.length; i++) {
      final (tk, gid) = _tokens[i];
      if (tk.length != t.length || !tk.containsAll(t)) continue;
      final allowed = _prefixEquip[_keys[i].split(' ').first];
      if (allowed != null && !allowed.contains(e.equipKey)) continue;
      return '$gifBase$gid.gif';
    }
    return null;
  }

  /// Palavras de um nome, inclusive as de 1 letra/número ("L-pull-up", "3/4").
  static Set<String> _gifWords(String rawName) {
    // "World's" é "worlds" (e não "world" + "s").
    final name = rawName.replaceAll("'s", 's');
    return _wordsOf(name);
  }

  static Set<String> _wordsOf(String name) => {
    ...nameTokens(name).map(_stem),
    ...RegExp(
      r'(?<![a-z0-9])[a-z0-9](?![a-z0-9])',
    ).allMatches(name.toLowerCase()).map((m) => m.group(0)!),
  }..removeAll(_neutral);

  /// Formas que `nameTokens` deixa passar: "flyes"→"flye"→"fly",
  /// "presses"→"presse"→"press", "crunches"→"crunche"→"crunch".
  static String _stem(String w) {
    if (w == 'flye') return 'fly';
    if (w.length > 4 &&
        (w.endsWith('sse') ||
            w.endsWith('che') ||
            w.endsWith('she') ||
            w.endsWith('xe'))) {
      return w.substring(0, w.length - 1);
    }
    return w;
  }

  /// Palavras que não mudam o exercício: "pegada média" é a pegada padrão,
  /// "grip" só repete "wide/close" e "bodyweight" é só peso corporal.
  static const _neutral = {'grip', 'medium', 'bodyweight'};

  /// Equivalências conferidas à mão: o exercício da base tem outro nome, mas o
  /// GIF mostra exatamente o mesmo movimento (nome em minúsculas → nome do GIF).
  static const _aliases = <String, String>{
    "power clean": "power clean",
    "jogging, treadmill": "walking on incline treadmill",
    "running, treadmill": "walking on incline treadmill",
    "stairmaster": "walking on stepmill",
    "step mill": "walking on stepmill",
    "bicycling, stationary": "stationary bike walk",
    "recumbent bike": "stationary bike walk",
    "close-grip ez-bar press": "ez-bar close-grip bench press",
    "jm press": "barbell jm bench press",
    "wide-grip decline barbell bench press": "barbell decline wide-grip press",
    "dumbbell one-arm triceps extension":
        "dumbbell single-arm triceps extension (on bench)",
    "alternate incline dumbbell curl": "dumbbell incline curl",
    "flexor incline dumbbell curls": "dumbbell incline curl",
    "bent over two-dumbbell row": "dumbbell bent over row",
    "one-arm dumbbell row": "dumbbell single-arm bent-over row",
    "barbell ab rollout": "barbell rollout",
    "barbell side bend": "barbell side bent",
    "barbell squat to a bench": "barbell bench squat",
    "front barbell squat to a bench": "barbell bench front squat",
    "barbell step ups": "barbell step-up",
    "bench press - powerlifting": "barbell bench press",
    "cable crunch": "cable kneeling crunch",
    "cable hammer curls - rope attachment": "cable hammer curl (with rope)",
    "cable rope overhead triceps extension":
        "cable overhead triceps extension (rope attachment)",
    "triceps overhead extension with rope":
        "cable overhead triceps extension (rope attachment)",
    "chair squat": "smith chair squat",
    "close-grip ez bar curl": "ez-bar close-grip curl",
    "decline ez bar triceps extension": "ez-bar decline triceps extension",
    "decline smith press": "smith decline bench press",
    "smith machine decline press": "smith decline bench press",
    "dumbbell shoulder press": "dumbbell seated shoulder press",
    "seated dumbbell press": "dumbbell seated shoulder press",
    "standing dumbbell press": "dumbbell standing overhead press",
    "dumbbell squat to a bench": "dumbbell bench squat",
    "dumbbell step ups": "dumbbell step-up",
    "front two-dumbbell raise": "dumbbell front raise",
    "incline dumbbell press": "dumbbell incline bench press",
    "hammer grip incline db bench press": "dumbbell incline hammer press",
    "incline dumbbell bench with palms facing in":
        "dumbbell palms in incline bench press",
    "incline dumbbell flyes - with a twist": "dumbbell incline twisted flyes",
    "kneeling high pulley row": "cable high row (kneeling)",
    "kneeling single-arm high pulley row":
        "cable single-arm straight back high row (kneeling)",
    "leg press": "sled 45° leg press",
    "lying cable curl": "cable lying biceps curl",
    "lying close-grip barbell triceps extension behind the head":
        "barbell lying close-grip triceps extension",
    "lying close-grip bar curl on high pulley": "cable lying close-grip curl",
    "lying t-bar row": "machine t bar row",
    "machine bench press": "machine chest press",
    "machine shoulder (military) press": "machine shoulder press",
    "one-arm high-pulley cable side bends": "cable side bend",
    "one-arm side laterals": "dumbbell single-arm lateral raise",
    "one leg barbell squat": "barbell single-leg squat",
    "one arm lat pulldown": "cable single-arm pulldown",
    "pull through": "cable pull through (with rope)",
    "reverse grip triceps pushdown": "cable reverse-grip pushdown",
    "reverse machine flyes": "machine seated reverse fly",
    "rope crunch": "cable standing crunch (with rope attachment)",
    "standing rope crunch": "cable standing crunch (with rope attachment)",
    "rocking standing calf raise": "barbell standing rocking leg calf raise",
    "seated barbell military press": "barbell seated overhead press",
    "side lateral raise": "dumbbell lateral raise",
    "side laterals to front raise": "dumbbell lateral to front raise",
    "seated side lateral raise": "dumbbell seated lateral raise",
    "standing dumbbell upright row": "dumbbell upright row",
    "standing dumbbell straight-arm front delt raise above head":
        "dumbbell standing front raise above head",
    "tricep dumbbell kickback": "dumbbell kickback",
    "triceps pushdown": "cable triceps pushdown (v-bar)",
    "triceps pushdown - v-bar attachment": "cable triceps pushdown (v-bar)",
    "triceps pushdown - rope attachment":
        "cable pushdown (with rope attachment)",
    "two-arm dumbbell preacher curl": "dumbbell preacher curl",
    "v-bar pulldown": "cable lateral pulldown with v-bar",
    "wide-grip lat pulldown": "cable lat pulldown full range of motion",
    "wide-grip pulldown behind the neck":
        "cable wide-grip rear pulldown behind neck",
    "wide stance barbell squat": "barbell wide squat",
    "weighted jump squat": "barbell jump squat",
    "sumo deadlift with bands": "barbell sumo deadlift",
    "sumo deadlift with chains": "barbell sumo deadlift",
    "rack pull with bands": "barbell rack pull",
    "smith machine behind the back shrug": "smith back shrug",
    "smith machine stiff-legged deadlift": "smith deadlift",
    "split squat with dumbbells": "dumbbell single leg split squat",
    "seated triceps press": "dumbbell seated triceps extension",
    "dips - triceps version": "triceps dip",
    "freehand jump squat": "jump squat",
    "close-grip push-up off of a dumbbell": "push-up close-grip off dumbbell",
    "elliptical trainer": "walk elliptical cross trainer",
    "walking, treadmill": "walking on incline treadmill",
  };

  /// Palavra que o GIF usa para o equipamento do exercício.
  static const _equipWord = <String, Set<String>>{
    'barbell': {'barbell'},
    'dumbbell': {'dumbbell'},
    'cable': {'cable'},
    'bands': {'band'},
    'kettlebells': {'kettlebell'},
    'e-z curl bar': {'ez', 'bar'},
    'medicine ball': {'medicine', 'ball'},
    'exercise ball': {'ball'},
  };

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
    'sled': {'machine'},
    'exercise': {'exercise ball'},
  };
}
