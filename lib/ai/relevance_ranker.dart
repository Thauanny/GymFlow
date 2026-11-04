import '../models/exercise.dart';
import 'goal_text.dart';

/// Dá uma nota 0..1 a cada exercício conforme o texto do objetivo.
abstract class RelevanceRanker {
  bool get usesModel;

  Future<Map<String, double>> scores(
    String goalText,
    List<Exercise> pool, {
    void Function(double progress)? onProgress,
  });
}

/// Busca simples por palavras-chave (não baixa nada).
class KeywordRanker implements RelevanceRanker {
  @override
  bool get usesModel => false;

  @override
  Future<Map<String, double>> scores(
    String goalText,
    List<Exercise> pool, {
    void Function(double progress)? onProgress,
  }) async {
    final terms = translateGoal(goalText).split(' ').where((t) => t.length > 2);
    if (terms.isEmpty) return {};
    int raw(Exercise e) {
      final text = e.aiText.toLowerCase();
      return terms.where(text.contains).length;
    }

    final max = pool.map(raw).fold<int>(0, (a, b) => a > b ? a : b);
    if (max == 0) return {};
    return {for (final e in pool) e.id: raw(e) / max};
  }
}
