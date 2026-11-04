import '../core/utils/text_tokens.dart';
import 'translation/pt_alt_names.dart';
import 'translation/pt_names.dart';
import '../domain/movement_patterns.dart';
import '../models/exercise.dart';
import 'alt.dart';
import 'equipment/equipment_catalog.dart';
import 'equipment/equipment_matcher.dart';
import 'gif_catalog.dart';
import 'muscle_rules.dart';

/// Sugere alternativas de equipamento/exercício para o mesmo músculo.
class AlternativesService {
  final GifCatalog _gifs;
  final List<Exercise> Function() _exercises;
  final Map<String, Set<String>> _muscleItems = {};

  AlternativesService(this._gifs, this._exercises);

  Set<String> _ownedKinds(Set<String> owned) => {
    for (final i in equipItems)
      if (owned.contains(i.id)) i.dbEquip,
  };

  /// Nome da alternativa em português: tradução própria, ou a curada do exercício
  /// equivalente, ou (último caso) a tradução automática por palavras.
  String altNamePt(Alt a) {
    final own = ptAltNames[a.name.toLowerCase()];
    if (own != null) return own;
    final e = exerciseForAlt(a);
    return exerciseNamePt(e.id.startsWith('alt-') ? a.name : e.name);
  }

  /// Exercício correspondente a uma alternativa (com instruções, se houver).
  Exercise exerciseForAlt(Alt a) {
    final t = nameTokens(a.name);
    for (final e in _exercises()) {
      final et = nameTokens(e.name);
      if (et.length == t.length && et.containsAll(t)) return e;
    }
    return Exercise.fromJson({
      'id': 'alt-${a.name}',
      'name': a.name,
      'equipment': a.equip,
      'primaryMuscles': [a.target],
    });
  }

  /// Aparelhos que trabalham um músculo.
  Set<String> itemsForMuscle(String muscle) =>
      _muscleItems.putIfAbsent(muscle, () {
        final ids = <String>{};
        for (final a in _gifs.alts) {
          if (!altWorksMuscle(a, muscle)) continue;
          final it = itemForAlt(a.name, a.equip);
          if (it != null) ids.add(it.id);
        }
        final rule = muscleRules[muscle];
        for (final e in _exercises()) {
          final direct =
              e.primary.contains(muscle) ||
              (muscle == 'glutes' && e.primary.contains('abductors'));
          if (!direct) continue;
          if (rule != null && rule.exclude.hasMatch(e.name)) continue;
          final it = itemForExercise(e);
          if (it != null) ids.add(it.id);
        }
        return ids;
      });

  /// Variações que trabalham o músculo; as de equipamentos que o usuário tem vêm primeiro.
  List<Alt> altsForMuscle(String muscle, Set<String> owned) {
    final kinds = _ownedKinds(owned);
    final out = [
      for (final a in _gifs.alts)
        if (altWorksMuscle(a, muscle)) a.withHave(kinds.contains(a.equip)),
    ];
    out.sort((a, b) {
      final h = (b.have ? 1 : 0) - (a.have ? 1 : 0);
      return h != 0 ? h : a.name.compareTo(b.name);
    });
    return out;
  }

  /// Mesmo movimento com outros equipamentos (máx. 2 por tipo de equipamento).
  List<Alt> alternativesFor(Exercise e, Set<String> owned, {int max = 8}) {
    final muscle = e.mainMuscle;
    if (muscle == null || _gifs.alts.isEmpty) return [];
    final kinds = _ownedKinds(owned);
    final move = movementOf(e.name);
    var pool = _gifs.alts
        .where((a) => a.target == gifTarget(muscle) && a.equip != e.equipKey)
        .toList();
    if (move != null) {
      final same = pool.where((a) => movementOf(a.name) == move).toList();
      if (same.length >= 3) pool = same;
    }
    final mine = nameTokens(e.name);
    int overlap(Alt a) => nameTokens(a.name).intersection(mine).length;
    pool.sort((a, b) {
      final h =
          (kinds.contains(b.equip) ? 1 : 0) - (kinds.contains(a.equip) ? 1 : 0);
      return h != 0 ? h : overlap(b) - overlap(a);
    });
    final perEquip = <String, int>{};
    final out = <Alt>[];
    for (final a in pool) {
      if ((perEquip[a.equip] ?? 0) >= 2) continue;
      perEquip[a.equip] = (perEquip[a.equip] ?? 0) + 1;
      out.add(a.withHave(kinds.contains(a.equip)));
      if (out.length >= max) break;
    }
    return out;
  }
}
