import '../../models/exercise.dart';
import '../../models/workout.dart';

enum VolumeLevel { low, ok, high }

VolumeLevel volumeLevel(double sets) => sets < 8
    ? VolumeLevel.low
    : (sets > 20 ? VolumeLevel.high : VolumeLevel.ok);

/// Séries por semana para cada músculo (secundário conta meia série).
Map<String, double> weeklyVolume(
  Iterable<Workout> workouts,
  Exercise? Function(String id) byId,
) {
  final out = <String, double>{};
  for (final w in workouts) {
    for (final it in w.items) {
      final e = byId(it.exerciseId);
      if (e == null || e.isCardio) continue;
      for (final m in e.primary) {
        out[m] = (out[m] ?? 0) + it.sets;
      }
      for (final m in e.secondary) {
        out[m] = (out[m] ?? 0) + it.sets / 2;
      }
    }
  }
  return out;
}
