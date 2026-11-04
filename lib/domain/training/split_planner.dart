import 'recovery.dart';
import 'training_profile.dart';

// Divisões clássicas de academia (ABC...), conforme o número de dias.
const _standard = {
  1: ['full'],
  2: ['upper', 'legs'],
  3: ['upper', 'legs', 'full'],
  4: ['chest_triceps', 'back_biceps', 'legs', 'shoulders_abs'],
  5: ['chest_triceps', 'back_biceps', 'legs', 'shoulders_abs', 'legs'],
  6: ['chest_triceps', 'back_biceps', 'legs', 'shoulders_abs', 'upper', 'legs'],
  7: [
    'chest_triceps',
    'back_biceps',
    'legs',
    'shoulders_abs',
    'upper',
    'legs',
    'cardio',
  ],
};

// Iniciantes repetem o corpo inteiro nos primeiros dias para treinar cada
// músculo com mais frequência e aprender os movimentos.
const _beginner = {
  1: ['full'],
  2: ['full', 'full'],
  3: ['full', 'full', 'full'],
  4: ['upper', 'legs', 'upper', 'legs'],
  5: ['upper', 'legs', 'full', 'upper', 'legs'],
};

/// Divide a semana entre os dias escolhidos: weekday (1..7) → id do foco.
Map<int, String> suggestSplit(Iterable<int> weekdays, TrainingProfile p) {
  final days = weekdays.toSet().toList()..sort();
  if (days.isEmpty) return {};
  final table = p.level == 'beginner'
      ? {..._standard, ..._beginner}
      : _standard;
  final split = table[days.length]!;
  final focus = {for (var i = 0; i < days.length; i++) days[i]: split[i]};
  return _restBetweenRepeats(focus);
}

/// Se um dia repetiria os músculos do dia anterior (inclusive domingo →
/// segunda), troca esse dia por cardio, que deixa o músculo descansar. Assim
/// a divisão sugerida nunca dispara o aviso de recuperação.
Map<int, String> _restBetweenRepeats(Map<int, String> focus) {
  final out = {...focus};
  bool conflicts(int d) {
    final next = d == 7 ? 1 : d + 1;
    final a = out[d], b = out[next];
    return a != null && b != null && sharedMuscles(a, b).isNotEmpty;
  }

  for (final d in focus.keys.toList()..sort()) {
    final next = d == 7 ? 1 : d + 1;
    if (!conflicts(d)) continue;
    // O dia que repete vira cardio. No domingo → segunda, é o domingo que
    // cede, para não mexer no primeiro treino da semana.
    out[d == 7 ? d : next] = 'cardio';
  }
  return out;
}
