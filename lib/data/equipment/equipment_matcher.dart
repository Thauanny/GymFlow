import '../../models/exercise.dart';
import '../../models/labels.dart';
import 'equipment_catalog.dart';

final _regexCache = <String, RegExp>{};

RegExp _re(String pattern) => _regexCache.putIfAbsent(
  pattern,
  () => RegExp(pattern, caseSensitive: false),
);

bool _patternMatches(EquipItem it, String name) =>
    it.pattern != null && _re(it.pattern!).hasMatch(name);

/// Aparelho do catálogo que corresponde a uma variação (nome + tipo de equipamento).
EquipItem? itemForAlt(String name, String equip) {
  final same = equipItems.where((i) => i.dbEquip == equip).toList();
  if (same.isEmpty) return null;
  for (final i in same) {
    if (_patternMatches(i, name)) return i;
  }
  return same.where((i) => i.rest).firstOrNull ?? same.first;
}

final _exerciseItemCache = <String, EquipItem?>{};

/// Aparelho necessário para fazer o exercício (null se não houver no catálogo).
EquipItem? itemForExercise(Exercise e) =>
    _exerciseItemCache.putIfAbsent(e.id, () {
      for (final it in equipItems) {
        if (itemMatches(it, e)) return it;
      }
      return null;
    });

bool itemMatches(EquipItem it, Exercise e) {
  if (e.equipKey != it.dbEquip) return false;
  if (it.pattern == null && !it.rest) return true;
  if (it.pattern != null) return _patternMatches(it, e.name);
  // "rest": o que nenhum item específico do mesmo grupo cobre.
  return !equipItems.any(
    (o) => o.dbEquip == it.dbEquip && _patternMatches(o, e.name),
  );
}

/// Nome do aparelho usado no exercício (ex.: "Puxada alta (pulldown)").
String equipmentLabelOf(Exercise e) =>
    itemForExercise(e)?.label ?? equipLabel(e.equipKey);

/// Aparelhos distintos de um treino, na ordem em que aparecem.
List<String> workoutEquipment(Iterable<Exercise> exercises) =>
    {for (final e in exercises) equipmentLabelOf(e)}.toList();
