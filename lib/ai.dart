import 'dart:convert';
import 'dart:js_interop';
import 'dart:math';

import 'models.dart';

@JS('gymAIReady')
external JSPromise<JSBoolean> _ready();

@JS('gymAIEmbed')
external JSPromise<JSString> _embed(JSString json);

/// Traduz termos comuns em PT para EN (base de exercícios é em inglês).
const _ptEn = {
  'peito': 'chest',
  'costas': 'back lats',
  'perna': 'legs quadriceps hamstrings',
  'pernas': 'legs quadriceps hamstrings',
  'gluteo': 'glutes',
  'glúteo': 'glutes',
  'glúteos': 'glutes',
  'ombro': 'shoulders',
  'ombros': 'shoulders',
  'braço': 'biceps triceps',
  'braços': 'biceps triceps',
  'biceps': 'biceps',
  'bíceps': 'biceps',
  'triceps': 'triceps',
  'tríceps': 'triceps',
  'abdomen': 'abdominals',
  'abdômen': 'abdominals',
  'barriga': 'abdominals',
  'panturrilha': 'calves',
  'força': 'strength',
  'hipertrofia': 'strength muscle growth',
  'alongamento': 'stretching',
  'cardio': 'cardio',
  'emagrecer': 'cardio plyometrics',
  'funcional': 'plyometrics strength',
};

String translateQuery(String q) {
  final words = q.toLowerCase().split(RegExp(r'[\s,;]+'));
  return words.map((w) => _ptEn[w] ?? w).join(' ');
}

class SemanticRanker {
  final Map<String, List<double>> _cache = {};
  bool modelReady = false;

  Future<bool> init() async {
    try {
      modelReady = (await _ready().toDart).toDart;
    } catch (_) {
      modelReady = false;
    }
    return modelReady;
  }

  Future<List<List<double>>> _embedBatch(List<String> texts) async {
    final res = await _embed(jsonEncode(texts).toJS).toDart;
    return (jsonDecode(res.toDart) as List)
        .map((v) => (v as List).map((n) => (n as num).toDouble()).toList())
        .toList();
  }

  /// Ordena exercícios por similaridade semântica com a consulta (IA no
  /// navegador). Sem modelo, cai para pontuação por palavras-chave.
  Future<List<Exercise>> rank(
    String query,
    List<Exercise> pool, {
    void Function(double)? onProgress,
  }) async {
    final q = translateQuery(
      query.trim().isEmpty ? 'full body strength' : query,
    );
    if (!modelReady) return _keywordRank(q, pool);
    try {
      final missing = pool.where((e) => !_cache.containsKey(e.id)).toList();
      for (var i = 0; i < missing.length; i += 32) {
        final chunk = missing.skip(i).take(32).toList();
        final vecs = await _embedBatch(
          chunk.map((e) => 'passage: ${e.aiText}').toList(),
        );
        for (var j = 0; j < chunk.length; j++) {
          _cache[chunk[j].id] = vecs[j];
        }
        onProgress?.call(min(1, (i + 32) / missing.length));
      }
      final qv = (await _embedBatch(['query: $q'])).first;
      final scored = {for (final e in pool) e: _dot(qv, _cache[e.id]!)};
      return (pool.toList()..sort((a, b) => scored[b]!.compareTo(scored[a]!)));
    } catch (_) {
      modelReady = false;
      return _keywordRank(q, pool);
    }
  }

  double _dot(List<double> a, List<double> b) {
    var s = 0.0;
    for (var i = 0; i < a.length; i++) {
      s += a[i] * b[i];
    }
    return s;
  }

  List<Exercise> _keywordRank(String q, List<Exercise> pool) {
    final terms = q.split(' ').where((t) => t.length > 2).toList();
    int score(Exercise e) {
      final t = e.aiText.toLowerCase();
      return terms.where(t.contains).length * 2 +
          terms.where((w) => e.primary.any((m) => m.contains(w))).length * 3;
    }

    return pool.toList()..sort((a, b) => score(b).compareTo(score(a)));
  }
}
