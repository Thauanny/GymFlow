enum TrainingGoal {
  hypertrophy('hypertrophy', 'Hipertrofia', 'Ganhar massa muscular'),
  strength('strength', 'Força', 'Levantar cargas maiores'),
  fatLoss('fatLoss', 'Emagrecimento', 'Mais gasto calórico, com cardio'),
  endurance('endurance', 'Resistência', 'Mais repetições, menos descanso');

  final String id, label, description;
  const TrainingGoal(this.id, this.label, this.description);

  static TrainingGoal byId(String? id) => TrainingGoal.values.firstWhere(
    (g) => g.id == id,
    orElse: () => TrainingGoal.hypertrophy,
  );
}

const levelOrder = ['beginner', 'intermediate', 'expert'];

int levelRank(String level) {
  final i = levelOrder.indexOf(level);
  return i < 0 ? 0 : i;
}

/// Preferências do usuário que guiam a geração do treino.
class TrainingProfile {
  final TrainingGoal goal;
  final String level;
  final int minutes;
  final String goalText;

  const TrainingProfile({
    this.goal = TrainingGoal.hypertrophy,
    this.level = 'intermediate',
    this.minutes = 60,
    this.goalText = '',
  });

  TrainingProfile copyWith({
    TrainingGoal? goal,
    String? level,
    int? minutes,
    String? goalText,
  }) => TrainingProfile(
    goal: goal ?? this.goal,
    level: level ?? this.level,
    minutes: minutes ?? this.minutes,
    goalText: goalText ?? this.goalText,
  );

  Map<String, dynamic> toJson() => {
    'goal': goal.id,
    'level': level,
    'min': minutes,
    'text': goalText,
  };

  factory TrainingProfile.fromJson(Map<String, dynamic> j) => TrainingProfile(
    goal: TrainingGoal.byId(j['goal'] as String?),
    level: levelOrder.contains(j['level'])
        ? j['level'] as String
        : 'intermediate',
    minutes: (j['min'] as int?) ?? 60,
    goalText: (j['text'] as String?) ?? '',
  );
}
