import '../../models/exercise.dart';
import 'training_profile.dart';

const _excludedCategories = {
  'stretching',
  'strongman',
  'olympic weightlifting',
};

/// Regras duras: o exercício pode entrar no treino deste usuário?
bool isEligible(Exercise e, TrainingProfile p) {
  if (_excludedCategories.contains(e.category)) return false;
  if (levelRank(e.level) > levelRank(p.level)) return false;
  if (e.category == 'plyometrics') {
    return p.goal == TrainingGoal.fatLoss || p.goal == TrainingGoal.endurance;
  }
  return true;
}
