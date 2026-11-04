import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../models/exercise.dart';
import '../../../models/labels.dart';
import '../../../models/workout.dart';
import '../../../state/catalog_cubit.dart';
import '../../../state/equipment_cubit.dart';
import '../../../state/nav_cubit.dart';
import '../../../state/workouts_cubit.dart';
import '../../widgets/app_card.dart';
import '../../widgets/exercise_thumb.dart';
import '../planner/planner_page.dart';
import '../workouts/workout_ticket_page.dart';

/// Destaque da Home: o treino de hoje (ou como montar um).
class TodayCard extends StatelessWidget {
  const TodayCard({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;
    return BlocBuilder<WorkoutsCubit, WorkoutsState>(
      builder: (context, s) {
        final todays = s.forWeekday(today);
        if (todays.isNotEmpty) return _Hero(todays.first, today);
        final ready = context.select<EquipmentCubit, bool>(
          (c) => c.state.available.isNotEmpty,
        );
        final scheduled = s.trainDays.contains(today);
        return _Empty(
          title: scheduled
              ? 'Hoje é dia de treino'
              : (s.workouts.isEmpty ? 'Monte seu plano' : 'Hoje é descanso'),
          message: scheduled
              ? 'Você ainda não tem o treino de ${weekdayFull[today - 1]}.'
              : (s.workouts.isEmpty
                    ? 'Escolha dias e objetivo e o GymFlow monta a semana para você.'
                    : _nextWorkoutMessage(s, today)),
          ready: ready,
        );
      },
    );
  }
}

/// "Aproveite para recuperar. Próximo treino: Quarta."
String _nextWorkoutMessage(WorkoutsState s, int today) {
  for (var i = 1; i <= 7; i++) {
    final d = (today - 1 + i) % 7 + 1;
    if (s.forWeekday(d).isNotEmpty) {
      return 'Aproveite para recuperar. Próximo treino: ${weekdayFull[d - 1]}.';
    }
  }
  return 'Aproveite para recuperar.';
}

class _Hero extends StatelessWidget {
  final Workout workout;
  final int today;
  const _Hero(this.workout, this.today);

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final catalog = context.read<CatalogCubit>();
    final preview = [
      for (final i in workout.items.take(5))
        if (catalog.byId(i.exerciseId) case final Exercise e) e,
    ];
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.volt,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -30,
            child: Icon(
              workout.focus.icon,
              size: narrow ? 170 : 240,
              color: p.onVolt.withValues(alpha: .07),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(narrow ? 22 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOJE · ${weekdayFull[today - 1].toUpperCase()}',
                  style: AppText.eyebrow(p.onVolt.withValues(alpha: .65)),
                ),
                const SizedBox(height: 8),
                Text(
                  workout.focus.label.toUpperCase(),
                  style: AppText.display(narrow ? 58 : 84, color: p.onVolt),
                ),
                const SizedBox(height: 10),
                Text(
                  '${workout.items.length} exercícios  ·  ~${workout.estimatedMinutes} min'
                  '${workout.doneCount > 0 ? '  ·  ${workout.doneCount} feitos' : ''}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: p.onVolt.withValues(alpha: .8),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in preview)
                      ExerciseThumb(e, size: narrow ? 46 : 58),
                  ],
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.onVolt,
                    foregroundColor: p.volt,
                  ),
                  onPressed: () => openTicket(context, workout),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    workout.doneCount > 0
                        ? 'Continuar treino'
                        : 'Começar treino',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String title, message;
  final bool ready;
  const _Empty({
    required this.title,
    required this.message,
    required this.ready,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return AppCard(
      radius: 30,
      padding: EdgeInsets.all(narrow ? 22 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: AppText.display(narrow ? 44 : 64)),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: p.muted, fontSize: 15)),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: ready
                    ? () => openPlanner(context)
                    : () => context.read<NavCubit>().go(AppTab.equipment),
                icon: Icon(
                  ready
                      ? Icons.auto_awesome_rounded
                      : Icons.fitness_center_rounded,
                ),
                label: Text(
                  ready ? 'Montar meu plano' : 'Escolher equipamentos',
                ),
              ),
              OutlinedButton(
                onPressed: () => context.read<NavCubit>().go(AppTab.workouts),
                child: const Text('Ver treinos'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
