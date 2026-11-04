const imageBase =
    'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/';

String frameUrl(String id, int frame) => '$imageBase$id/$frame.jpg';

/// Exercício da base free-exercise-db.
class Exercise {
  final String id, name, level, category;
  final String? equipment, force, mechanic;
  final List<String> primary, secondary, instructions, images;

  Exercise.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      name = j['name'] as String,
      level = (j['level'] ?? 'beginner') as String,
      category = (j['category'] ?? '') as String,
      equipment = j['equipment'] as String?,
      force = j['force'] as String?,
      mechanic = j['mechanic'] as String?,
      primary = List<String>.from(j['primaryMuscles'] ?? []),
      secondary = List<String>.from(j['secondaryMuscles'] ?? []),
      instructions = List<String>.from(j['instructions'] ?? []),
      images = List<String>.from(j['images'] ?? []);

  String get equipKey => equipment ?? 'body only';
  String? get imageUrl => images.isEmpty ? null : '$imageBase${images.first}';
  String? get mainMuscle => primary.isEmpty ? null : primary.first;
  bool get isCardio => category == 'cardio';

  /// Composto = trabalha mais de uma articulação/músculo.
  bool get isCompound =>
      mechanic == 'compound' || (mechanic == null && secondary.isNotEmpty);

  String get aiText =>
      '$name. ${primary.join(', ')}. ${secondary.join(', ')}. $category. $equipKey. $level';
}
