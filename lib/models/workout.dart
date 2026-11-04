import 'day_focus.dart';
import 'plan_item.dart';

class Workout {
  final String id;
  String name;
  String day; // id de [DayFocus]
  int? weekday; // 1 = segunda ... 7 = domingo
  final List<PlanItem> items;

  /// Alongamentos do dia (ficha à parte): `reps` = segundos de cada posição.
  final List<PlanItem> stretches;

  Workout(
    this.id,
    this.name,
    this.items, {
    this.day = 'full',
    this.weekday,
    List<PlanItem>? stretches,
  }) : stretches = stretches ?? [];

  DayFocus get focus => focusById(day);
  int get doneCount => items.where((i) => i.done).length;
  double get progress => items.isEmpty ? 0 : doneCount / items.length;

  /// Duração estimada: ~45 s por série + descanso (cardio: os minutos do item).
  int get estimatedMinutes {
    var seconds = 0;
    for (final i in items) {
      seconds += i.restSec == 0 ? i.reps * 60 : i.sets * (45 + i.restSec);
    }
    return (seconds / 60).round();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'wd': weekday,
    'day': day,
    'items': items.map((e) => e.toJson()).toList(),
    if (stretches.isNotEmpty) 'st': stretches.map((e) => e.toJson()).toList(),
  };

  factory Workout.fromJson(Map<String, dynamic> j) => Workout(
    j['id'],
    j['name'],
    (j['items'] as List).map((e) => PlanItem.fromJson(e)).toList(),
    weekday: j['wd'] as int?,
    stretches: [
      for (final e in (j['st'] as List? ?? const [])) PlanItem.fromJson(e),
    ],
    day: focusById(j['day'] as String?).id,
  );
}
