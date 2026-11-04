import 'alt.dart';

/// Nome do músculo no free-exercise-db → nome usado no índice de GIFs.
const muscleToGifTarget = {
  'chest': 'pectorals',
  'shoulders': 'deltoids',
  'lats': 'latissimus dorsi',
  'middle back': 'upper back',
  'lower back': 'erector spinae',
  'traps': 'trapezius',
};

String gifTarget(String muscle) => muscleToGifTarget[muscle] ?? muscle;

/// Regras que refinam o rótulo do dataset: `exclude` remove itens que não
/// trabalham o músculo; `include` puxa itens rotulados em outros músculos.
class MuscleRule {
  final RegExp exclude, include;
  final Set<String> from;
  const MuscleRule(this.exclude, this.include, this.from);
}

final muscleRules = <String, MuscleRule>{
  'glutes': MuscleRule(
    RegExp(
      r'stretch|push[- ]?up|toe touch|twist|kicks|\bclean\b(?!-grip)|snatch|tire flip|turkish|'
      r'hug knees|iron cross|frog|march sit|spider|pike|lying lifting|'
      r'pass through|potty|hip flexor|rotation|piriformis|arms apart|'
      r'hamstring curl|roller|lying glutes',
      caseSensitive: false,
    ),
    RegExp(
      r'glute|hip abduct|abductor|good morning|straight[- ]leg deadlift|hip thrust|'
      r'donkey kick|fire hydrant|clamshell',
      caseSensitive: false,
    ),
    {'hamstrings', 'abductors', 'erector spinae', 'quadriceps'},
  ),
};

final _notWork = RegExp(r'stretch|calf|triceps|biceps', caseSensitive: false);

bool altWorksMuscle(Alt a, String muscle) {
  final target = gifTarget(muscle);
  final r = muscleRules[muscle];
  if (r == null) return a.target == target;
  if (a.target == target) return !r.exclude.hasMatch(a.name);
  return r.from.contains(a.target) &&
      r.include.hasMatch(a.name) &&
      !_notWork.hasMatch(a.name);
}
