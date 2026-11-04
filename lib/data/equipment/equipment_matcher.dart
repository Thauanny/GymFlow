import '../../models/exercise.dart';
import '../../models/labels.dart';
import 'equipment_catalog.dart';
import 'exercise_region.dart';

final _regexCache = <String, RegExp>{};

RegExp _re(String pattern) => _regexCache.putIfAbsent(
  pattern,
  () => RegExp(pattern, caseSensitive: false),
);

bool _patternMatches(EquipItem it, String name) =>
    it.pattern != null && _re(it.pattern!).hasMatch(name);

/// Aparelho do catálogo que corresponde a uma variação (nome + equipamento +
/// músculo alvo do índice de GIFs).
EquipItem? itemForAlt(String name, String equip, [String? target]) {
  final e = Exercise.fromJson({
    'id': 'alt-$name',
    'name': name,
    'equipment': equip,
    if (target != null) 'primaryMuscles': [_muscleOfTarget(target)],
  });
  return itemForExercise(e) ??
      equipItems.where((i) => i.dbEquip == equip).firstOrNull;
}

String _muscleOfTarget(String target) => switch (target) {
  'pectorals' => 'chest',
  'deltoids' => 'shoulders',
  'latissimus dorsi' => 'lats',
  'upper back' => 'middle back',
  'erector spinae' => 'lower back',
  'trapezius' => 'traps',
  _ => target,
};

final _exerciseItemCache = <String, EquipItem?>{};

/// Aparelho dono do exercício: **um só**. Cada exercício aparece em um único
/// card da Academia (o primeiro do catálogo que o reconhece).
EquipItem? itemForExercise(Exercise e) =>
    _exerciseItemCache.putIfAbsent(e.id, () {
      for (final it in equipItems) {
        if (_matchesByPattern(it, e)) return it;
      }
      return _fallbackItem(e);
    });

bool itemMatches(EquipItem it, Exercise e) => itemForExercise(e)?.id == it.id;

bool _matchesByPattern(EquipItem it, Exercise e) {
  if (e.equipKey != it.dbEquip && !it.alsoEquip.contains(e.equipKey)) {
    return false;
  }
  final regions = it.regions;
  if (regions != null) return regions.contains(regionOf(e));
  if (it.pattern == null && !it.rest) return true;
  if (it.pattern != null) return _patternMatches(it, e.name);
  // "rest": o que nenhum item específico do mesmo grupo cobre.
  return !equipItems.any(
    (o) => o.dbEquip == it.dbEquip && _patternMatches(o, e.name),
  );
}

/// Máquinas que nenhum padrão reconhece ficam na máquina que trabalha o mesmo
/// músculo.
const _fallbackByMuscle = <String, String>{
  'machine|abdominals': 'm_ab',
  'machine|abductors': 'm_abd',
  'machine|adductors': 'm_add',
  'machine|calves': 'm_calf',
  'machine|shoulders': 'm_shoulder',
  'machine|lower back': 'm_glute',
  'machine|forearms': 'm_arm',
  'machine|glutes': 'm_glute',
  'machine|hamstrings': 'm_legcurl',
  'machine|lats': 'm_pulldown',
  'machine|middle back': 'm_row',
  'machine|chest': 'm_chest',
  'machine|quadriceps': 'm_legext',
  'machine|triceps': 'm_tricep',
  'machine|biceps': 'm_arm',
  'machine|traps': 'm_shrug',
};

EquipItem? _fallbackItem(Exercise e) {
  final id = _fallbackByMuscle['${e.equipKey}|${e.mainMuscle}'];
  if (id == null) return null;
  return equipItems.where((i) => i.id == id).firstOrNull;
}

/// Nome do aparelho usado no exercício (ex.: "Puxada alta (pulldown)").
String equipmentLabelOf(Exercise e) =>
    itemForExercise(e)?.label ?? equipLabel(e.equipKey);

/// Aparelhos distintos de um treino, na ordem em que aparecem.
List<String> workoutEquipment(Iterable<Exercise> exercises) =>
    {for (final e in exercises) equipmentLabelOf(e)}.toList();
