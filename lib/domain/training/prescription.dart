import 'day_template.dart';
import 'training_profile.dart';

/// Séries, repetições e descanso de um exercício.
class Prescription {
  final int sets, reps, restSec;
  const Prescription(this.sets, this.reps, this.restSec);
}

const _compound = {
  TrainingGoal.hypertrophy: Prescription(4, 8, 90),
  TrainingGoal.strength: Prescription(5, 5, 150),
  TrainingGoal.fatLoss: Prescription(3, 12, 40),
  TrainingGoal.endurance: Prescription(3, 15, 45),
};

const _isolation = {
  TrainingGoal.hypertrophy: Prescription(3, 12, 60),
  TrainingGoal.strength: Prescription(3, 8, 90),
  TrainingGoal.fatLoss: Prescription(3, 15, 30),
  TrainingGoal.endurance: Prescription(3, 18, 30),
};

/// Iniciantes fazem uma série a menos (mínimo 2) para se adaptar.
Prescription prescribe(TrainingGoal goal, SlotRole role, String level) {
  final base = (role == SlotRole.compound ? _compound : _isolation)[goal]!;
  final sets = level == 'beginner' ? (base.sets - 1).clamp(2, 6) : base.sets;
  return Prescription(sets, base.reps, base.restSec);
}

/// Quantidade de exercícios de força para o tempo disponível.
int exerciseCountFor(int minutes) => (3 + minutes / 15).round().clamp(4, 10);
