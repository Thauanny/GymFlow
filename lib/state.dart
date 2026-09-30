import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'ai.dart';
import 'equipment.dart';
import 'models.dart';

const exercisesUrl =
    'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json';

const gifBase = 'https://static.exercisedb.dev/media/';

class Alt {
  final String name, gif, equip, target;
  final bool have;
  const Alt(this.name, this.gif, this.equip, this.target, [this.have = false]);
  Alt withHave(bool h) => Alt(name, gif, equip, target, h);
}

class AppState extends ChangeNotifier {
  Map<String, String> gifByName = {};
  Map<String, String> itemGifs = {};
  final Map<String, String?> _gifCache = {};
  final List<(Set<String>, String)> _gifTokens = [];

  static const _stop = {
    'the',
    'with',
    'on',
    'of',
    'a',
    'to',
    'machine',
    'lever',
    'leverage',
    'sled',
    'exercise',
    'and',
    'in',
    'for',
    'full',
    'range',
    'motion',
  };

  static Set<String> _tokens(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .split(' ')
      .where((w) => w.length > 1 && !_stop.contains(w))
      .map(
        (w) => w.length > 3 && w.endsWith('s') && !w.endsWith('ss')
            ? w.substring(0, w.length - 1)
            : w,
      )
      .toSet();

  Future<void> _loadGifs() async {
    try {
      Future<dynamic> read(String p) async =>
          jsonDecode(await rootBundle.loadString('assets/gif/$p.json'));
      gifByName = Map<String, String>.from(await read('exercises'));
      itemGifs = {
        for (final g in (await read('items') as Map<String, dynamic>).values)
          ...Map<String, String>.from(g as Map),
      };
      _alts = [];
      for (final equip in equipmentInfo.keys) {
        final file = equip.replaceAll(' ', '_');
        for (final a in (await read('alts/$file') as List)) {
          _alts.add(
            Alt(a[0] as String, '$gifBase${a[1]}.gif', equip, a[2] as String),
          );
        }
      }
      for (final e in gifByName.entries) {
        _gifTokens.add((_tokens(e.key), e.value));
      }
    } catch (_) {}
  }

  String? itemGif(String id) =>
      itemGifs[id] == null ? null : '$gifBase${itemGifs[id]}.gif';

  List<Alt> _alts = [];

  /// Exercício correspondente a uma alternativa (instruções do free-exercise-db quando houver).
  Exercise exerciseForAlt(Alt a) {
    final t = _tokens(a.name);
    for (final e in exercises) {
      final et = _tokens(e.name);
      if (et.length == t.length && et.containsAll(t)) return e;
    }
    return Exercise.fromJson({
      'id': 'alt-${a.name}',
      'name': a.name,
      'equipment': a.equip,
      'primaryMuscles': [a.target],
    });
  }

  static const _muscleMap = {
    'chest': 'pectorals',
    'shoulders': 'deltoids',
    'lats': 'latissimus dorsi',
    'middle back': 'upper back',
    'lower back': 'erector spinae',
    'traps': 'trapezius',
  };

  /// Palavras que identificam o padrão de movimento.
  static const _moves = [
    ('fly', ['fly', 'flye', 'butterfly', 'crossover', 'pec deck']),
    ('press', ['press', 'military']),
    ('row', ['row']),
    ('pulldown', ['pulldown', 'pull-down', 'pull up', 'pull-up', 'chin']),
    ('curl', ['curl']),
    ('extension', ['extension', 'pushdown', 'pressdown', 'kickback', 'skull']),
    ('raise', ['raise']),
    ('squat', ['squat', 'lunge', 'leg press']),
    ('deadlift', ['deadlift', 'thrust', 'bridge', 'hyperextension']),
    ('crunch', ['crunch', 'sit-up', 'twist', 'chop']),
    ('shrug', ['shrug']),
    ('dip', ['dip']),
  ];

  static String? _moveOf(String name) {
    final n = name.toLowerCase();
    for (final (k, words) in _moves) {
      if (words.any(n.contains)) return k;
    }
    return null;
  }

  final Map<String, Set<String>> _muscleItems = {};

  /// Regras que refinam o rótulo do dataset: `exclude` remove itens que não
  /// trabalham o músculo; `include` puxa itens rotulados em outros músculos.
  static final _muscleRules =
      <String, ({RegExp exclude, RegExp include, Set<String> from})>{
        'glutes': (
          exclude: RegExp(
            r'stretch|push[- ]?up|toe touch|twist|kicks|\bclean\b(?!-grip)|snatch|tire flip|turkish|'
            r'hug knees|iron cross|frog|march sit|spider|pike|lying lifting|'
            r'pass through|potty|hip flexor|rotation|piriformis|arms apart|'
            r'hamstring curl|roller|lying glutes',
            caseSensitive: false,
          ),
          include: RegExp(
            r'glute|hip abduct|abductor|good morning|straight[- ]leg deadlift|hip thrust|'
            r'donkey kick|fire hydrant|clamshell',
            caseSensitive: false,
          ),
          from: {'hamstrings', 'abductors', 'erector spinae', 'quadriceps'},
        ),
      };

  static final _notWork = RegExp(
    r'stretch|calf|triceps|biceps',
    caseSensitive: false,
  );

  bool _altHasMuscle(Alt a, String muscle) {
    final target = _muscleMap[muscle] ?? muscle;
    final r = _muscleRules[muscle];
    if (r == null) return a.target == target;
    if (a.target == target) return !r.exclude.hasMatch(a.name);
    return r.from.contains(a.target) &&
        r.include.hasMatch(a.name) &&
        !_notWork.hasMatch(a.name);
  }

  /// Aparelhos que trabalham um músculo (pelos exercícios e pelas variações com GIF).
  Set<String> itemsForMuscle(String muscle) =>
      _muscleItems.putIfAbsent(muscle, () {
        final ids = <String>{};
        for (final a in _alts) {
          if (!_altHasMuscle(a, muscle)) continue;
          final it = itemForAlt(a.name, a.equip);
          if (it != null) ids.add(it.id);
        }
        final r = _muscleRules[muscle];
        for (final e in exercises) {
          if (!e.primary.contains(muscle) &&
              !(muscle == 'glutes' && e.primary.contains('abductors'))) {
            continue;
          }
          if (r != null && r.exclude.hasMatch(e.name)) continue;
          for (final it in equipItems) {
            if (itemMatches(it, e)) {
              ids.add(it.id);
              break;
            }
          }
        }
        return ids;
      });

  /// Todas as variações que trabalham um músculo (chave de [muscleNames]).
  /// As de equipamentos já salvos vêm primeiro.
  List<Alt> altsForMuscle(String muscle) {
    bool have(Alt a) => equipItems.any(
      (i) => savedEquipment.contains(i.id) && i.dbEquip == a.equip,
    );
    final out = [
      for (final a in _alts)
        if (_altHasMuscle(a, muscle)) a.withHave(have(a)),
    ];
    out.sort((a, b) {
      final h = (b.have ? 1 : 0) - (a.have ? 1 : 0);
      return h != 0 ? h : a.name.compareTo(b.name);
    });
    return out;
  }

  /// Variações do mesmo exercício com outros equipamentos (com GIF).
  /// As que usam equipamentos já salvos pelo usuário vêm primeiro.
  List<Alt> alternativesFor(Exercise e, {int max = 8}) {
    if (e.primary.isEmpty || _alts.isEmpty) return [];
    final target = _muscleMap[e.primary.first] ?? e.primary.first;
    final move = _moveOf(e.name);
    bool have(Alt a) => equipItems.any(
      (i) => savedEquipment.contains(i.id) && i.dbEquip == a.equip,
    );
    var pool = _alts
        .where((a) => a.target == target && a.equip != e.equipKey)
        .toList();
    if (move != null) {
      final same = pool.where((a) => _moveOf(a.name) == move).toList();
      if (same.length >= 3) pool = same;
    }
    pool.sort((a, b) {
      final h = (have(b) ? 1 : 0) - (have(a) ? 1 : 0);
      if (h != 0) return h;
      final ta = _tokens(a.name).intersection(_tokens(e.name)).length;
      final tb = _tokens(b.name).intersection(_tokens(e.name)).length;
      return tb - ta;
    });
    final perEquip = <String, int>{};
    final out = <Alt>[];
    for (final a in pool) {
      if ((perEquip[a.equip] ?? 0) >= 2) continue;
      perEquip[a.equip] = (perEquip[a.equip] ?? 0) + 1;
      out.add(a.withHave(have(a)));
      if (out.length >= max) break;
    }
    return out;
  }

  /// GIF instrutivo correspondente ao exercício (por similaridade de nome).
  String? gifFor(Exercise e) {
    if (_gifCache.containsKey(e.id)) return _gifCache[e.id];
    final t = _tokens(e.name);
    var best = 0.0;
    String? id;
    for (final (tk, gid) in _gifTokens) {
      final inter = t.intersection(tk).length;
      if (inter == 0) continue;
      final score = inter / (t.length + tk.length - inter);
      if (score > best) {
        best = score;
        id = gid;
      }
    }
    return _gifCache[e.id] = best >= .5 ? '$gifBase$id.gif' : null;
  }

  List<Exercise> exercises = [];
  Set<String> equipment = {};
  Set<String> savedEquipment = {};
  Set<int> savedDumbbells = {};
  Set<int> dumbbells = {};
  Set<String> openSections = {};
  Map<String, int> _counts = {};
  List<Workout> workouts = [];

  /// Dias da semana (1 = segunda) em que o usuário quer treinar.
  Set<int> trainDays = {};

  /// Treinos gerados/criados que só vão para "Treinos" quando todos os dias
  /// escolhidos estiverem prontos.
  final Map<int, Workout> drafts = {};
  int? aiWeekday;
  List<LogEntry> logs = [];
  List<WeightEntry> weights = [];
  bool loading = true;
  String? error;
  final ranker = SemanticRanker();
  late SharedPreferences _p;

  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    final valid = equipItems.map((i) => i.id).toSet();
    final saved = _p.getStringList('equip2') ?? [];
    equipment = {
      ...saved.where(valid.contains),
      if (saved.contains('dumbbell'))
        ...equipItems.where((i) => i.dbEquip == 'dumbbell').map((i) => i.id),
    };
    dumbbells = (_p.getStringList('dumbbells') ?? []).map(int.parse).toSet();
    _syncSections();
    openSections.addAll(
      (_p.getStringList('open_sections') ?? []).where((s) => s != 'custom'),
    );
    savedEquipment = {...equipment};
    savedDumbbells = {...dumbbells};
    await _loadGifs();
    workouts = _decode('workouts', Workout.fromJson);
    trainDays = (_p.getStringList('train_days') ?? []).map(int.parse).toSet();
    logs = _decode('logs', LogEntry.fromJson);
    weights = _decode('weights', WeightEntry.fromJson);
    await _loadExercises();
  }

  List<T> _decode<T>(String key, T Function(Map<String, dynamic>) f) {
    final s = _p.getString(key);
    if (s == null) return [];
    return (jsonDecode(s) as List)
        .map((e) => f(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _loadExercises() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final cached = _p.getString('exercises_cache');
      String body;
      if (cached != null) {
        body = cached;
      } else {
        final r = await http.get(Uri.parse(exercisesUrl));
        if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
        body = utf8.decode(r.bodyBytes);
        try {
          await _p.setString('exercises_cache', body);
        } catch (_) {}
      }
      exercises = (jsonDecode(body) as List)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList();
      _counts = {
        for (final it in equipItems)
          it.id: exercises.where((e) => itemMatches(it, e)).length,
      };
    } catch (e) {
      error = 'Não foi possível carregar a base de exercícios: $e';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> retry() => _loadExercises();

  Exercise? byId(String id) {
    for (final e in exercises) {
      if (e.id == id) return e;
    }
    return null;
  }

  List<Exercise> get available => _availableFor(savedEquipment);

  /// Exercícios da seleção atual (ainda não salva).
  List<Exercise> get draftAvailable => _availableFor(equipment);

  List<Exercise> _availableFor(Set<String> ids) {
    final sel = equipItems.where((i) => ids.contains(i.id)).toList();
    return exercises.where((e) => sel.any((i) => itemMatches(i, e))).toList();
  }

  bool get dirty =>
      equipment.length != savedEquipment.length ||
      !equipment.containsAll(savedEquipment) ||
      dumbbells.length != savedDumbbells.length ||
      !dumbbells.containsAll(savedDumbbells);

  Map<String, int> get equipmentCounts => _counts;

  /// Grava a seleção no armazenamento local do navegador (sem expiração).
  void saveEquipment() {
    savedEquipment = {...equipment};
    savedDumbbells = {...dumbbells};
    _p.setStringList('equip2', equipment.toList());
    _p.setStringList('open_sections', openSections.toList());
    _p.setStringList('dumbbells', dumbbells.map((e) => '$e').toList());
    notifyListeners();
  }

  void _saveEquip() => notifyListeners();

  void toggleEquipment(String key) {
    equipment.contains(key) ? equipment.remove(key) : equipment.add(key);
    _saveEquip();
  }

  void setEquipment(Set<String> all) {
    equipment = all;
    _syncSections();
    _saveEquip();
  }

  void _syncSections() {
    openSections = {
      for (final it in equipItems)
        if (equipment.contains(it.id)) it.section,
    };
  }

  /// Abre/fecha uma categoria.
  void toggleSection(String sec) {
    if (openSections.contains(sec)) {
      openSections.remove(sec);
      equipment.removeWhere((id) {
        final s = equipItems
            .where((i) => i.id == id)
            .map((i) => i.section)
            .firstOrNull;
        return s == null || !openSections.contains(s);
      });
    } else {
      openSections.add(sec);
    }
    _saveEquip();
  }

  /// Troca um aparelho por outro (ou apenas adiciona, se [removeId] for nulo).
  void swapEquipment(String? removeId, String addId) {
    if (removeId != null) equipment.remove(removeId);
    equipment.add(addId);
    final sec = equipItems.firstWhere((i) => i.id == addId).section;
    openSections.add(sec);
    _saveEquip();
  }

  void toggleDumbbell(int kg) {
    dumbbells.contains(kg) ? dumbbells.remove(kg) : dumbbells.add(kg);
    _saveEquip();
  }

  /// Carga de halter sugerida (kg) conforme o objetivo, entre as disponíveis.
  int? dumbbellFor(String objective) {
    if (dumbbells.isEmpty) return null;
    final s = dumbbells.toList()..sort();
    final f = switch (objective) {
      'força' => .75,
      'resistência' => .25,
      _ => .5,
    };
    return s[((s.length - 1) * f).round()];
  }

  void _save() {
    _p.setString(
      'workouts',
      jsonEncode(workouts.map((e) => e.toJson()).toList()),
    );
    _p.setString('logs', jsonEncode(logs.map((e) => e.toJson()).toList()));
    _p.setString(
      'weights',
      jsonEncode(weights.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
  }

  void addWorkout(Workout w) {
    workouts.insert(0, w);
    _save();
  }

  /// Insere um treino novo ou substitui o existente (mesmo id).
  void saveWorkout(Workout w) {
    final i = workouts.indexWhere((x) => x.id == w.id);
    if (i >= 0) {
      workouts[i] = w;
    } else {
      workouts.insert(0, w);
    }
    _save();
  }

  void deleteWorkout(Workout w) {
    workouts.remove(w);
    _save();
  }

  void touch() => _save();

  List<int> get sortedDays => trainDays.toList()..sort();

  Set<int> get coveredDays => {
    for (final w in workouts)
      if (w.weekday != null) w.weekday!,
    ...drafts.keys,
  };

  List<int> get missingDays => [
    for (final d in sortedDays)
      if (!coveredDays.contains(d)) d,
  ];

  void setTrainDays(Set<int> days) {
    trainDays = {...days};
    drafts.removeWhere((k, _) => !trainDays.contains(k));
    _p.setStringList('train_days', trainDays.map((e) => '$e').toList());
    notifyListeners();
  }

  /// Divisão sugerida conforme a quantidade de dias escolhidos.
  String suggestType(int weekday) {
    const splits = {
      1: ['mixed'],
      2: ['upper1', 'lower1'],
      3: ['upper1', 'lower1', 'cardio'],
      4: ['upper1', 'lower1', 'upper1', 'lower1'],
      5: ['upper1', 'lower1', 'cardio', 'upper1', 'lower1'],
      6: ['upper1', 'lower1', 'cardio', 'upper1', 'lower1', 'mixed'],
      7: ['upper1', 'lower1', 'cardio', 'upper1', 'lower1', 'mixed', 'cardio'],
    };
    final days = sortedDays;
    final i = days.indexOf(weekday);
    final n = days.length;
    if (i < 0 || n == 0) return 'mixed';
    return splits[n]![i];
  }

  void setDraft(Workout w) {
    final d = w.weekday!;
    drafts.removeWhere((k, v) => v.id == w.id || k == d);
    drafts[d] = w;
    if (!trainDays.contains(d)) setTrainDays({...trainDays, d});
    notifyListeners();
  }

  void removeDraft(int day) {
    drafts.remove(day);
    notifyListeners();
  }

  void commitDrafts() {
    for (final w in drafts.values) {
      saveWorkout(w);
    }
    drafts.clear();
    notifyListeners();
  }

  void addLog(LogEntry l) {
    logs.insert(0, l);
    _save();
  }

  void addWeight(double kg) {
    weights.add(WeightEntry(DateTime.now(), kg));
    _save();
  }

  int get streakDays {
    final days = logs
        .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
        .toSet();
    var d = DateTime.now();
    d = DateTime(d.year, d.month, d.day);
    if (!days.contains(d)) d = d.subtract(const Duration(days: 1));
    var n = 0;
    while (days.contains(d)) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }
}
