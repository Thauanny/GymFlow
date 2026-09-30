import 'package:flutter/material.dart' show IconData, Icons;

const imageBase =
    'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/';

const equipmentInfo = <String, (String, String)>{
  'body only': ('Peso corporal', '🤸'),
  'machine': ('Máquinas', '🏋️'),
  'dumbbell': ('Halteres', '💪'),
  'barbell': ('Barra', '🏗️'),
  'cable': ('Cabos / Polia', '🔗'),
  'kettlebells': ('Kettlebell', '🔔'),
  'bands': ('Elásticos', '🎗️'),
  'medicine ball': ('Medicine ball', '🏀'),
  'exercise ball': ('Bola suíça', '🔵'),
  'e-z curl bar': ('Barra W', '〰️'),
  'foam roll': ('Rolo de espuma', '🧻'),
  'other': ('Outros', '✨'),
};

const muscleNames = <String, String>{
  'abdominals': 'Abdômen',
  'chest': 'Peito',
  'quadriceps': 'Quadríceps',
  'hamstrings': 'Posterior de coxa',
  'glutes': 'Glúteos',
  'lats': 'Dorsal',
  'biceps': 'Bíceps',
  'triceps': 'Tríceps',
  'shoulders': 'Ombros',
  'calves': 'Panturrilha',
  'middle back': 'Costas (meio)',
  'lower back': 'Lombar',
  'forearms': 'Antebraço',
  'traps': 'Trapézio',
  'abductors': 'Abdutores',
  'adductors': 'Adutores',
  'neck': 'Pescoço',
};

const levelNames = <String, String>{
  'beginner': 'Iniciante',
  'intermediate': 'Intermediário',
  'expert': 'Avançado',
};

String equipLabel(String e) => equipmentInfo[e]?.$1 ?? e;
String muscleLabel(String m) => muscleNames[m] ?? m;

class Exercise {
  final String id, name, level, category;
  final String? equipment, force;
  final List<String> primary, secondary, instructions, images;

  Exercise.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      name = j['name'] as String,
      level = (j['level'] ?? 'beginner') as String,
      category = (j['category'] ?? '') as String,
      equipment = j['equipment'] as String?,
      force = j['force'] as String?,
      primary = List<String>.from(j['primaryMuscles'] ?? []),
      secondary = List<String>.from(j['secondaryMuscles'] ?? []),
      instructions = List<String>.from(j['instructions'] ?? []),
      images = List<String>.from(j['images'] ?? []);

  String get equipKey => equipment ?? 'body only';
  String? get imageUrl => images.isEmpty ? null : '$imageBase${images.first}';

  String get aiText =>
      '$name. ${primary.join(', ')}. ${secondary.join(', ')}. $category. $equipKey. $level';
}

class PlanItem {
  final String exerciseId;
  int sets, reps;
  bool done;
  PlanItem(this.exerciseId, this.sets, this.reps, {this.done = false});

  Map<String, dynamic> toJson() => {
    'e': exerciseId,
    's': sets,
    'r': reps,
    'd': done,
  };
  factory PlanItem.fromJson(Map<String, dynamic> j) =>
      PlanItem(j['e'], j['s'], j['r'], done: j['d'] == true);
}

/// Divisão dos dias de treino (ordem de exibição).
const dayTypes = <String, (String, IconData)>{
  'upper1': ('Superior 1', Icons.accessibility_new),
  'upper2': ('Superior 2', Icons.accessibility_new),
  'lower1': ('Inferior 1', Icons.directions_walk),
  'lower2': ('Inferior 2', Icons.directions_walk),
  'cardio': ('Cardio', Icons.directions_run),
  'mixed': ('Misto', Icons.shuffle),
};

class Workout {
  final String id;
  String name;
  String day;
  int? weekday; // 1 = segunda ... 7 = domingo
  final List<PlanItem> items;
  Workout(this.id, this.name, this.items, {this.day = 'mixed', this.weekday});

  int get doneCount => items.where((i) => i.done).length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'wd': weekday,
    'day': day,
    'items': items.map((e) => e.toJson()).toList(),
  };
  factory Workout.fromJson(Map<String, dynamic> j) => Workout(
    j['id'],
    j['name'],
    (j['items'] as List).map((e) => PlanItem.fromJson(e)).toList(),
    weekday: j['wd'] as int?,
    day: dayTypes.containsKey(j['day']) ? j['day'] : 'mixed',
  );
}

const weekdayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
const weekdayFull = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];

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
