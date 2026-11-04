import '../../models/exercise.dart';

/// Chave usada na lista de "evitar" para a polia dupla (estação com cabos dos
/// dois lados, que costuma ficar ocupada em academias pequenas).
const dualCableKey = 'dual_cable';

/// Exercícios que dependem da estação de polia dos dois lados.
const _dualCableExercises = {
  'Cable Crossover',
  'Low Cable Crossover',
  'Single-Arm Cable Crossover',
  'Cable Iron Cross',
  'Cable Rear Delt Fly',
  'Flat Bench Cable Flyes',
  'Incline Cable Flye',
  'Cable Chest Press',
  'Incline Cable Chest Press',
  'Standing Cable Chest Press',
  'Cable Judo Flip',
  'Alternating Cable Shoulder Press',
};

bool usesDualCable(Exercise e) => _dualCableExercises.contains(e.name);
