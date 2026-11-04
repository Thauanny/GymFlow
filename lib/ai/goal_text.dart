/// Interpreta o objetivo escrito pelo usuário (PT-BR) sem precisar de modelo.
const _muscleWords = <String, List<String>>{
  'peito': ['chest'],
  'peitoral': ['chest'],
  'costas': ['lats', 'middle back'],
  'dorsal': ['lats'],
  'perna': ['quadriceps', 'hamstrings'],
  'pernas': ['quadriceps', 'hamstrings'],
  'coxa': ['quadriceps', 'hamstrings'],
  'quadriceps': ['quadriceps'],
  'posterior': ['hamstrings'],
  'gluteo': ['glutes'],
  'gluteos': ['glutes'],
  'bumbum': ['glutes'],
  'ombro': ['shoulders'],
  'ombros': ['shoulders'],
  'braco': ['biceps', 'triceps'],
  'bracos': ['biceps', 'triceps'],
  'biceps': ['biceps'],
  'triceps': ['triceps'],
  'abdomen': ['abdominals'],
  'abdominal': ['abdominals'],
  'barriga': ['abdominals'],
  'core': ['abdominals'],
  'panturrilha': ['calves'],
  'trapezio': ['traps'],
  'lombar': ['lower back'],
  'antebraco': ['forearms'],
};

const _goalWords = <String, String>{
  'forca': 'strength',
  'hipertrofia': 'muscle growth',
  'emagrecer': 'cardio plyometrics',
  'funcional': 'plyometrics strength',
  'alongamento': 'stretching',
  'cardio': 'cardio',
};

const _muscleEnglish = <String, String>{
  'chest': 'chest',
  'lats': 'back lats',
  'middle back': 'back',
  'quadriceps': 'quadriceps',
  'hamstrings': 'hamstrings',
  'glutes': 'glutes',
  'shoulders': 'shoulders',
  'biceps': 'biceps',
  'triceps': 'triceps',
  'abdominals': 'abdominals',
  'calves': 'calves',
  'traps': 'traps',
  'lower back': 'lower back',
  'forearms': 'forearms',
};

const _accents = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'é': 'e',
  'ê': 'e',
  'í': 'i',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ú': 'u',
  'ç': 'c',
};

String normalizeText(String s) =>
    s.toLowerCase().split('').map((c) => _accents[c] ?? c).join();

List<String> _words(String text) => normalizeText(
  text,
).split(RegExp(r'[^a-z]+')).where((w) => w.isNotEmpty).toList();

/// Músculos citados no texto (ex.: "quero fortalecer glúteos e costas").
Set<String> musclesFromText(String text) => {
  for (final w in _words(text)) ...?_muscleWords[w],
};

/// Traduz termos do objetivo para inglês (a base de exercícios é em inglês).
String translateGoal(String text) {
  final out = <String>[];
  for (final w in _words(text)) {
    if (_goalWords.containsKey(w)) {
      out.add(_goalWords[w]!);
    } else if (_muscleWords.containsKey(w)) {
      for (final m in _muscleWords[w]!) {
        out.add(_muscleEnglish[m] ?? m);
      }
    } else {
      out.add(w);
    }
  }
  return out.join(' ');
}
