import 'dart:convert';
import 'dart:js_interop';
import 'dart:math';

import '../models/exercise.dart';
import 'goal_text.dart';
import 'relevance_ranker.dart';

@JS('gymAIReady')
external JSPromise<JSBoolean> _ready();

@JS('gymAIEmbed')
external JSPromise<JSString> _embed(JSString json);

/// Ranqueia por significado usando um modelo de embeddings no navegador
/// (opcional, baixa o modelo na primeira vez). Sem modelo, usa palavras-chave.
class SemanticRanker implements RelevanceRanker {
  final RelevanceRanker _fallback = KeywordRanker();
  final Map<String, List<double>> _cache = {};
  bool _ready0 = false;

  @override
  bool get usesModel => _ready0;

  Future<bool> init() async {
    try {
      _ready0 = (await _ready().toDart).toDart;
    } catch (_) {
      _ready0 = false;
    }
    return _ready0;
  }

  Future<List<List<double>>> _embedBatch(List<String> texts) async {
    final res = await _embed(jsonEncode(texts).toJS).toDart;
    return (jsonDecode(res.toDart) as List)
        .map((v) => (v as List).map((n) => (n as num).toDouble()).toList())
        .toList();
  }

  @override
  Future<Map<String, double>> scores(
    String goalText,
    List<Exercise> pool, {
    void Function(double progress)? onProgress,
  }) async {
    if (!_ready0 && !await init()) {
      return _fallback.scores(goalText, pool, onProgress: onProgress);
    }
    try {
      await _embedMissing(pool, onProgress);
      final q = (await _embedBatch([
        'query: ${translateGoal(goalText)}',
      ])).first;
      final raw = {for (final e in pool) e.id: _dot(q, _cache[e.id]!)};
      return _normalize(raw);
    } catch (_) {
      _ready0 = false;
      return _fallback.scores(goalText, pool, onProgress: onProgress);
    }
  }

  Future<void> _embedMissing(
    List<Exercise> pool,
    void Function(double)? onProgress,
  ) async {
    final missing = pool.where((e) => !_cache.containsKey(e.id)).toList();
    for (var i = 0; i < missing.length; i += 32) {
      final chunk = missing.skip(i).take(32).toList();
      final vecs = await _embedBatch([
        for (final e in chunk) 'passage: ${e.aiText}',
      ]);
      for (var j = 0; j < chunk.length; j++) {
        _cache[chunk[j].id] = vecs[j];
      }
      onProgress?.call(min(1, (i + 32) / missing.length));
    }
  }

  double _dot(List<double> a, List<double> b) {
    var s = 0.0;
    for (var i = 0; i < a.length; i++) {
      s += a[i] * b[i];
    }
    return s;
  }

  Map<String, double> _normalize(Map<String, double> raw) {
    if (raw.isEmpty) return raw;
    final lo = raw.values.reduce(min);
    final hi = raw.values.reduce(max);
    final span = hi - lo;
    if (span == 0) return {for (final k in raw.keys) k: 0};
    return {for (final e in raw.entries) e.key: (e.value - lo) / span};
  }
}

/// Cria o ranqueador semântico (web).
RelevanceRanker createSemanticRanker() => SemanticRanker();
