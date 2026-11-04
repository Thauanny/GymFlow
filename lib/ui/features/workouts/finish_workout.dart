import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/workout.dart';
import '../../../state/progress_cubit.dart';
import '../../../state/workouts_cubit.dart';
import '../../widgets/dialogs.dart';

/// Salva o treino concluído no calendário de progresso (pede a duração) e zera
/// o checklist. Retorna se salvou.
Future<bool> finishWorkout(BuildContext context, Workout w) async {
  final minutes = await askNumber(
    context,
    title: 'Salvar no calendário',
    label: 'Duração (min)',
    initial: '45',
    confirm: 'Salvar',
  );
  if (minutes == null || !context.mounted) return false;
  context.read<ProgressCubit>().finish(w, minutes.round());
  for (final i in w.items) {
    i.setsDone = 0;
  }
  context.read<WorkoutsCubit>().touch();
  return true;
}
