import 'package:flutter/material.dart' show IconData, Icons;

/// Foco de um dia de treino (o que será trabalhado).
class DayFocus {
  final String id, label;
  final IconData icon;
  final List<String> muscles;
  const DayFocus(this.id, this.label, this.icon, this.muscles);

  bool get isCardio => id == 'cardio';
  bool get isFullBody => id == 'full';
}

const _upperMuscles = [
  'chest',
  'lats',
  'middle back',
  'shoulders',
  'biceps',
  'triceps',
  'traps',
  'forearms',
];
const _lowerMuscles = [
  'quadriceps',
  'hamstrings',
  'glutes',
  'calves',
  'abductors',
  'adductors',
];

/// Categorias usuais de academia (estilo ABC), sem sobreposição entre elas.
const dayFocuses = <String, DayFocus>{
  'chest_triceps': DayFocus(
    'chest_triceps',
    'Peito e tríceps',
    Icons.fitness_center_rounded,
    ['chest', 'triceps'],
  ),
  'back_biceps': DayFocus(
    'back_biceps',
    'Costas e bíceps',
    Icons.sports_gymnastics_rounded,
    ['lats', 'middle back', 'traps', 'biceps', 'forearms', 'lower back'],
  ),
  'shoulders_abs': DayFocus(
    'shoulders_abs',
    'Ombros e abdômen',
    Icons.self_improvement_rounded,
    ['shoulders', 'traps', 'abdominals'],
  ),
  'legs': DayFocus(
    'legs',
    'Pernas e glúteos',
    Icons.directions_walk_rounded,
    _lowerMuscles,
  ),
  'upper': DayFocus(
    'upper',
    'Superior completo',
    Icons.accessibility_new_rounded,
    [..._upperMuscles, 'abdominals'],
  ),
  'full': DayFocus('full', 'Corpo inteiro', Icons.bolt_rounded, [
    ..._upperMuscles,
    ..._lowerMuscles,
    'abdominals',
    'lower back',
  ]),
  'cardio': DayFocus('cardio', 'Cardio', Icons.directions_run_rounded, []),
};

/// Ids de versões anteriores do app → categoria atual.
const _legacyFocus = {
  'push': 'chest_triceps',
  'pull': 'back_biceps',
  'lower': 'legs',
  'upper1': 'upper',
  'upper2': 'upper',
  'lower1': 'legs',
  'lower2': 'legs',
  'mixed': 'full',
};

/// Resolve um id (inclusive os antigos) para um foco válido.
DayFocus focusById(String? id) =>
    dayFocuses[id] ?? dayFocuses[_legacyFocus[id]] ?? dayFocuses['full']!;
