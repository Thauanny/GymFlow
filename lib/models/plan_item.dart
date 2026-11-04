/// Exercício dentro de um treino, com prescrição.
class PlanItem {
  final String exerciseId;
  int sets, reps, restSec, setsDone;
  double? kg;

  PlanItem(
    this.exerciseId,
    this.sets,
    this.reps, {
    this.restSec = 60,
    this.kg,
    this.setsDone = 0,
  });

  /// Exercício concluído = todas as séries feitas.
  bool get done => setsDone >= sets;
  set done(bool v) => setsDone = v ? sets : 0;

  PlanItem copy() => PlanItem(
    exerciseId,
    sets,
    reps,
    restSec: restSec,
    kg: kg,
    setsDone: setsDone,
  );

  Map<String, dynamic> toJson() => {
    'e': exerciseId,
    's': sets,
    'r': reps,
    'd': done,
    'sd': setsDone,
    'rs': restSec,
    if (kg != null) 'k': kg,
  };

  factory PlanItem.fromJson(Map<String, dynamic> j) => PlanItem(
    j['e'],
    j['s'],
    j['r'],
    setsDone: (j['sd'] as int?) ?? (j['d'] == true ? j['s'] as int : 0),
    restSec: (j['rs'] as int?) ?? 60,
    kg: (j['k'] as num?)?.toDouble(),
  );
}
