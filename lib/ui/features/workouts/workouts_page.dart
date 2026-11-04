import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/labels.dart';
import '../../../state/equipment_cubit.dart';
import '../../../state/nav_cubit.dart';
import '../../../state/workouts_cubit.dart';
import '../../widgets/notice_banner.dart';
import '../../widgets/page_body.dart';
import '../../widgets/section_title.dart';
import '../planner/planner_page.dart';
import 'missing_day_card.dart';
import 'plan_history.dart';
import 'plan_sheets.dart';
import 'rest_day_card.dart';
import 'week_picker.dart';
import 'workout_card.dart';

/// Semana de treino: escolha o dia e veja (ou monte) o treino dele.
class WorkoutsPage extends StatefulWidget {
  const WorkoutsPage({super.key});

  @override
  State<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends State<WorkoutsPage> {
  int _day = DateTime.now().weekday;

  /// Sem plano: "Montar plano". Com plano: "Mudar plano" e "Evoluir".
  List<Widget> _actions(BuildContext context, WorkoutsState s) {
    final hasPlan = s.workouts.any((w) => w.weekday != null);
    if (!hasPlan) {
      return [
        FilledButton.icon(
          onPressed: () => openPlanner(context),
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('Montar plano'),
        ),
      ];
    }
    return [
      OutlinedButton.icon(
        onPressed: () => showEvolveSheet(
          context,
          day: _day,
          dayHasWorkout: s.forWeekday(_day).isNotEmpty,
        ),
        icon: const Icon(Icons.trending_up_rounded),
        label: const Text('Evoluir'),
      ),
      FilledButton.icon(
        onPressed: () => showChangePlanSheet(context, day: _day),
        icon: const Icon(Icons.autorenew_rounded),
        label: const Text('Mudar plano'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final noEquipment = context.select<EquipmentCubit, bool>(
      (c) => c.state.saved.isEmpty,
    );
    return BlocBuilder<WorkoutsCubit, WorkoutsState>(
      builder: (context, s) {
        final workouts = s.forWeekday(_day);
        return PageBody(
          title: 'Treinos',
          subtitle: 'Sua semana, dia a dia.',
          actions: _actions(context, s),
          children: [
            if (noEquipment)
              NoticeBanner(
                text: 'Nenhum equipamento selecionado.',
                action: 'Escolher',
                onTap: () => context.read<NavCubit>().go(AppTab.equipment),
              ),
            WeekPicker(
              state: s,
              selected: _day,
              onSelect: (d) => setState(() => _day = d),
            ),
            SectionTitle(
              weekdayFull[_day - 1],
              trailing: workouts.isEmpty && s.trainDays.contains(_day)
                  ? TextButton(
                      onPressed: () => context
                          .read<WorkoutsCubit>()
                          .setTrainDays({...s.trainDays}..remove(_day)),
                      child: const Text('Tornar descanso'),
                    )
                  : null,
            ),
            for (final w in workouts) WorkoutCard(w),
            if (workouts.isEmpty)
              s.trainDays.contains(_day)
                  ? MissingDayCard(_day)
                  : RestDayCard(_day),
            if (s.withoutDay.isNotEmpty) ...[
              const SectionTitle('Sem dia definido'),
              for (final w in s.withoutDay) WorkoutCard(w),
            ],
            const PlanHistorySection(),
          ],
        );
      },
    );
  }
}
