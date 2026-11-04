/// Padrões de movimento reconhecidos pelo nome do exercício.
const _moves = [
  ('fly', ['fly', 'flye', 'butterfly', 'crossover', 'pec deck']),
  ('press', ['press', 'military']),
  ('row', ['row']),
  ('pulldown', ['pulldown', 'pull-down', 'pull up', 'pull-up', 'chin']),
  ('curl', ['curl']),
  ('extension', ['extension', 'pushdown', 'pressdown', 'kickback', 'skull']),
  ('raise', ['raise']),
  ('squat', ['squat', 'lunge', 'leg press']),
  ('deadlift', ['deadlift', 'thrust', 'bridge', 'hyperextension']),
  ('crunch', ['crunch', 'sit-up', 'twist', 'chop']),
  ('shrug', ['shrug']),
  ('dip', ['dip']),
];

String? movementOf(String name) {
  final n = name.toLowerCase();
  for (final (key, words) in _moves) {
    if (words.any(n.contains)) return key;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Família de movimento (para trocar um exercício por outro "do mesmo jeito").
// A ordem importa: o primeiro padrão que combina vence.
// ---------------------------------------------------------------------------

final _families = <(String, RegExp)>[
  ('bridge', RegExp(r'hip thrust|glute bridge|hip raise|lying lifting|bridge')),
  (
    'hinge',
    RegExp(
      r'deadlift|romanian|stiff|good morning|pull[- ]?through|rack pull|'
      r'hyperextension|back extension|swing',
    ),
  ),
  ('lunge', RegExp(r'lunge|split squat|step[- ]?ups?|bulgarian')),
  ('legpress', RegExp(r'leg press')),
  ('squat', RegExp(r'squat|hack|thruster')),
  ('legext', RegExp(r'leg extension')),
  ('legcurl', RegExp(r'leg curl|hamstring curl|glute[- ]?ham')),
  ('calf', RegExp(r'calf')),
  ('abduct', RegExp(r'abduct|adduct')),
  ('fly', RegExp(r'\bfly|flye|butterfly|crossover|pec deck|reverse fly')),
  ('pulldown', RegExp(r'pulldown|pull-?down|pull-?up|chin-?up|pullover')),
  ('row', RegExp(r'\brow|face pull')),
  (
    'vpress',
    RegExp(
      r'shoulder press|overhead press|military|arnold|push press|'
      r'behind (the )?neck|seated (dumbbell )?press',
    ),
  ),
  (
    'hpress',
    RegExp(
      r'bench press|chest press|floor press|push-?up|\bdip|close-grip press',
    ),
  ),
  ('raise', RegExp(r'raise|shrug|upright')),
  ('curl', RegExp(r'curl')),
  (
    'triext',
    RegExp(r'extension|pushdown|pressdown|kickback|skull|press-?down|jm press'),
  ),
  ('core', RegExp(r'crunch|sit-?up|twist|chop|rollout|leg raise|plank|v-up')),
];

/// Família do movimento ("hinge", "squat", "hpress"...), ou null se não houver.
String? movementFamily(String name) {
  final n = name.toLowerCase();
  for (final (key, re) in _families) {
    if (re.hasMatch(n)) return key;
  }
  return null;
}

/// Músculos que contam como "o mesmo" ao trocar um exercício da [family]: os
/// rótulos da base variam (o terra na polia vem como quadríceps, o terra com
/// barra como lombar), então o movimento manda e o músculo só confirma.
Set<String> relatedMuscles(String? family, String muscle) {
  const groups = <String, Set<String>>{
    'hinge': {'glutes', 'hamstrings', 'lower back', 'quadriceps'},
    'bridge': {'glutes', 'hamstrings'},
    'squat': {'quadriceps', 'glutes', 'hamstrings'},
    'lunge': {'quadriceps', 'glutes', 'hamstrings'},
    'legpress': {'quadriceps', 'glutes'},
    'pulldown': {'lats', 'middle back'},
    'row': {'middle back', 'lats'},
    'vpress': {'shoulders', 'triceps'},
    'hpress': {'chest', 'triceps', 'shoulders'},
  };
  final g = groups[family];
  return {muscle, if (g != null && g.contains(muscle)) ...g};
}
