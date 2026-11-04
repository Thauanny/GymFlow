import '../../domain/movement_patterns.dart';
import '../../models/exercise.dart';

final _cardioFree = RegExp(
  r'rope jumping|jump rope|bicycling|skating|hands bike|ergometer',
);
final _bar = RegExp(
  r'pull-?up|chin|muscle[- ]?up|\bdips?\b|\bdip\b|hang|rope climb|rings?\b|'
  r'inverted|suspended (row|push)|london bridge|one handed',
);
final _plyo = RegExp(
  r'jump|hop|leap|bound|skip|shuffle|sprint|push-off|depth|drop push|'
  r'heavy bag|quick',
);

/// Região do corpo (ou "tipo de trabalho") de um exercício. É o que decide em
/// qual card da Academia ele fica: cada exercício pertence a **um** só.
///
/// Usa o movimento e o músculo juntos, porque os rótulos de músculo da base
/// variam (o terra na polia vem como quadríceps, o terra com barra como lombar).
String regionOf(Exercise e) {
  final equip = e.equipKey;
  if (e.category == 'stretching' &&
      (equip == 'body only' || equip == 'other')) {
    return 'stretch';
  }
  final n = e.name.toLowerCase();
  if (e.category == 'plyometrics' && equip == 'body only') return 'o_plyo';
  if (equip == 'other') {
    if (_cardioFree.hasMatch(n)) return 'o_cardio';
    if (e.category == 'plyometrics' || _plyo.hasMatch(n)) return 'o_plyo';
    if (_bar.hasMatch(n)) return 'o_bar';
    if (e.mainMuscle == 'abdominals') return 'o_core';
    return 'o_strong';
  }
  final family = movementFamily(e.name);
  if (family == 'hinge' || family == 'bridge') return 'posterior';
  if (family == 'squat' ||
      family == 'lunge' ||
      family == 'legpress' ||
      family == 'legext') {
    return 'quads';
  }
  if (family == 'legcurl') return 'posterior';
  if (family == 'calf') return 'calves';
  return switch (e.mainMuscle) {
    'chest' => 'chest',
    'lats' || 'middle back' || 'lower back' => 'back',
    'shoulders' || 'traps' || 'neck' => 'shoulders',
    'biceps' || 'forearms' => 'biceps',
    'triceps' => 'triceps',
    'quadriceps' => 'quads',
    'glutes' || 'hamstrings' || 'adductors' || 'abductors' => 'posterior',
    'calves' => 'calves',
    _ => 'core',
  };
}
