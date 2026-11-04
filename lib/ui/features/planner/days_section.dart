import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../models/day_focus.dart';
import '../../../models/labels.dart';
import '../../../state/planner_cubit.dart';
import '../../../state/planner_state.dart';
import '../../../state/workouts_cubit.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_title.dart';
import '../../widgets/weekday_selector.dart';

/// Dias de treino e a função (foco) de cada um.
class DaysSection extends StatelessWidget {
  const DaysSection({super.key});

  @override
  Widget build(BuildContext context) {
    final planner = context.read<PlannerCubit>();
    final days = context.watch<WorkoutsCubit>().state.sortedDays;
    final s = context.watch<PlannerCubit>().state;
    final p = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          'Dias da semana',
          step: 3,
          hint: 'Escolha quando treina. A divisão é sugerida automaticamente.',
          trailing: days.isEmpty
              ? null
              : TextButton.icon(
                  onPressed: planner.autoSplit,
                  icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                  label: const Text('Sugerir divisão'),
                ),
        ),
        WeekdaySelector(
          selected: days.toSet(),
          marked: s.drafts.keys.toSet(),
          onChanged: planner.setDays,
        ),
        if (days.isNotEmpty) const SizedBox(height: 18),
        for (final d in days) _DayCard(day: d, state: s),
        for (final w in planner.warnings)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, size: 18, color: p.warn),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(w, style: TextStyle(fontSize: 13, color: p.warn)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  final int day;
  final PlannerState state;
  const _DayCard({required this.day, required this.state});

  @override
  Widget build(BuildContext context) {
    final planner = context.read<PlannerCubit>();
    final focus = focusById(state.focusFor(day));
    final emphasis = state.emphasisFor(day);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              weekdayFull[day - 1].toUpperCase(),
              style: AppText.display(26),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final f in dayFocuses.values)
                  ChoiceChip(
                    avatar: Icon(f.icon, size: 16),
                    label: Text(f.label),
                    selected: focus.id == f.id,
                    onSelected: (_) => planner.setFocus(day, f.id),
                  ),
              ],
            ),
            if (focus.muscles.isNotEmpty && !focus.isFullBody) ...[
              const SizedBox(height: 10),
              Text(
                'Dar destaque (opcional)',
                style: TextStyle(fontSize: 12, color: context.pal.muted),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final m in focus.muscles)
                    FilterChip(
                      label: Text(muscleLabel(m)),
                      selected: emphasis.contains(m),
                      onSelected: (_) => planner.toggleEmphasis(day, m),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
