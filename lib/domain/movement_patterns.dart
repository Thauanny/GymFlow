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
