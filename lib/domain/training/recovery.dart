import '../../models/day_focus.dart';
import '../../models/labels.dart';

/// Dois focos seguidos pesam nos mesmos músculos (3 ou mais em comum)?
/// Cardio não pesa em nenhum: serve de descanso para o músculo.
List<String> sharedMuscles(String focusA, String focusB) {
  final a = focusById(focusA), b = focusById(focusB);
  if (a.isCardio || b.isCardio) return const [];
  final shared = a.muscles.toSet().intersection(b.muscles.toSet());
  return shared.length >= 3 ? shared.toList() : const [];
}

/// Avisos quando o mesmo grupo muscular é treinado em dias seguidos.
List<String> recoveryWarnings(Map<int, String> focusByDay) {
  final out = <String>[];
  for (final d in focusByDay.keys) {
    final next = d == 7 ? 1 : d + 1;
    final other = focusByDay[next];
    if (other == null) continue;
    final shared = sharedMuscles(focusByDay[d]!, other);
    if (shared.isNotEmpty) {
      out.add(
        '${weekdayFull[d - 1]} e ${weekdayFull[next - 1]} repetem músculos '
        '(${shared.take(3).map(muscleLabel).join(', ')}). '
        'Considere um dia de descanso entre eles.',
      );
    }
  }
  return out;
}
