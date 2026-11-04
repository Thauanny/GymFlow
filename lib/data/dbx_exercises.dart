import '../models/exercise.dart';
import 'alt.dart';
import 'gif_catalog.dart';
import 'muscle_rules.dart';

/// Músculo do índice de GIFs → músculo do app (o inverso de [gifTarget]).
final _muscleOfTarget = {
  for (final e in muscleToGifTarget.entries) e.value: e.key,
};

String? _muscle(String target) {
  const own = {
    'abdominals',
    'glutes',
    'biceps',
    'triceps',
    'quadriceps',
    'hamstrings',
    'calves',
    'forearms',
    'adductors',
    'abductors',
  };
  if (own.contains(target)) return target;
  return _muscleOfTarget[target];
}

final _stretch = RegExp(r'stretch|foam roll|roller');
// Cardio de verdade: aparelhos e movimentos contínuos. "Caminhada do fazendeiro"
// e "avanço com sprint" são de força, não de cardio.
final _cardio = RegExp(
  r'treadmill|elliptical|stepmill|stairmaster|stair climber|stationary bike|'
  r'\bbike\b|bicycle|rowing machine|ergometer|skierg|jump rope|jumping jack',
);
final _plyo = RegExp(r'jump|hop\b|bound|plyo|clap|skater');
final _expert = RegExp(
  r'snatch|clean|jerk|muscle[- ]?up|pistol|planche|human flag|front lever|'
  r'back lever|dragon|maltese|iron cross|handstand|one arm (chin|pull)|'
  r'single-arm (chin|pull)|archer|typewriter',
);
final _compound = RegExp(
  r'squat|lunge|press|row|pull-?up|chin-?up|pulldown|deadlift|dip\b|push-?up|'
  r'thrust|clean|snatch|jerk|step[- ]?up|bridge|hyperextension|good morning|'
  r'burpee|thruster',
);

/// Exercícios que existem só no índice de GIFs (ExerciseDB) e não na base com
/// fotos: viram exercícios de verdade, com o GIF do próprio nome. Assim a
/// geração de treino também sugere os mais simples (peso corporal, elástico...).
List<Exercise> exercisesFromGifIndex(
  List<Alt> alts,
  List<Exercise> base,
  GifCatalog gifs,
) {
  final usedGifs = {for (final e in base) ?gifs.gifFor(e)};
  final names = {for (final e in base) e.name.toLowerCase()};
  final out = <Exercise>[];
  for (final a in alts) {
    final muscle = _muscle(a.target);
    if (muscle == null || usedGifs.contains(a.gif)) continue;
    if (!names.add(a.name.toLowerCase())) continue;
    final n = a.name.toLowerCase();
    final category = _stretch.hasMatch(n)
        ? 'stretching'
        : (_cardio.hasMatch(n) && !n.contains('crunch'))
        ? 'cardio'
        : _plyo.hasMatch(n)
        ? 'plyometrics'
        : 'strength';
    final e = Exercise.fromJson({
      'id': 'dbx-${a.gif.split('/').last.replaceAll('.gif', '')}',
      'name': a.name,
      'equipment': a.equip,
      'category': category,
      'level': _expert.hasMatch(n) ? 'expert' : 'beginner',
      'mechanic': _compound.hasMatch(n) ? 'compound' : 'isolation',
      'primaryMuscles': [muscle],
      'secondaryMuscles': <String>[],
    });
    out.add(e);
    gifs.bind(e.id, a.gif);
  }
  return out;
}
