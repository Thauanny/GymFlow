import '../../models/day_focus.dart';
import '../../models/labels.dart';

/// Avisos quando o mesmo grupo muscular é treinado em dias seguidos.
List<String> recoveryWarnings(Map<int, String> focusByDay) {
  final out = <String>[];
  for (final d in focusByDay.keys) {
    final next = d == 7 ? 1 : d + 1;
    final other = focusByDay[next];
    if (other == null) continue;
    final a = focusById(focusByDay[d]);
    final b = focusById(other);
    if (a.isCardio || b.isCardio) continue;
    final shared = a.muscles.toSet().intersection(b.muscles.toSet());
    if (shared.length >= 3) {
      out.add(
        '${weekdayFull[d - 1]} e ${weekdayFull[next - 1]} repetem músculos '
        '(${shared.take(3).map(muscleLabel).join(', ')}). '
        'Considere um dia de descanso entre eles.',
      );
    }
  }
  return out;
}
