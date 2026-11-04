import 'workout.dart';

/// Treinos que foram substituídos (por "Mudar plano", "Evoluir" ou ao salvar
/// um plano novo) e ficam guardados no histórico.
class ArchivedPlan {
  final String id;
  final DateTime date;
  final String label;
  final List<Workout> workouts;

  const ArchivedPlan({
    required this.id,
    required this.date,
    required this.label,
    required this.workouts,
  });

  Set<int> get weekdays => {
    for (final w in workouts)
      if (w.weekday != null) w.weekday!,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'd': date.toIso8601String(),
    'l': label,
    'w': workouts.map((w) => w.toJson()).toList(),
  };

  factory ArchivedPlan.fromJson(Map<String, dynamic> j) => ArchivedPlan(
    id: j['id'] as String,
    date: DateTime.parse(j['d'] as String),
    label: j['l'] as String,
    workouts: [
      for (final w in j['w'] as List)
        Workout.fromJson(w as Map<String, dynamic>),
    ],
  );
}
