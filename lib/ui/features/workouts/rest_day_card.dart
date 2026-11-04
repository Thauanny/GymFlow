import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../state/planner_cubit.dart';
import '../../../state/workouts_cubit.dart';
import '../../widgets/app_card.dart';

/// Dia sem treino: convida a transformar o dia em treino.
class RestDayCard extends StatelessWidget {
  final int weekday;
  const RestDayCard(this.weekday, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final days = context.read<WorkoutsCubit>().state.trainDays;
    return AppCard(
      color: p.softTints[2],
      borderColor: Colors.transparent,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DIA DE DESCANSO', style: AppText.display(34)),
          const SizedBox(height: 4),
          Text(
            'Recuperar também faz parte do treino.',
            style: TextStyle(color: p.text.withValues(alpha: .7)),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () =>
                context.read<PlannerCubit>().setDays({...days, weekday}),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Treinar neste dia'),
          ),
        ],
      ),
    );
  }
}
