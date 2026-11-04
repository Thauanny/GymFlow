class LogEntry {
  final DateTime date;
  final String workoutName;
  final int exercises, minutes;
  LogEntry(this.date, this.workoutName, this.exercises, this.minutes);

  Map<String, dynamic> toJson() => {
    'd': date.toIso8601String(),
    'n': workoutName,
    'e': exercises,
    'm': minutes,
  };
  factory LogEntry.fromJson(Map<String, dynamic> j) =>
      LogEntry(DateTime.parse(j['d']), j['n'], j['e'], j['m']);
}

class WeightEntry {
  final DateTime date;
  final double kg;
  WeightEntry(this.date, this.kg);

  Map<String, dynamic> toJson() => {'d': date.toIso8601String(), 'k': kg};
  factory WeightEntry.fromJson(Map<String, dynamic> j) =>
      WeightEntry(DateTime.parse(j['d']), (j['k'] as num).toDouble());
}
