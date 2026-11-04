import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/translation/pt_names.dart';
import '../../../models/exercise.dart';
import '../../../models/labels.dart';
import '../../../state/catalog_cubit.dart';
import '../../../state/planner_cubit.dart';
import '../../../state/planner_state.dart';
import '../../widgets/app_card.dart';
import '../../../data/equipment/equipment_matcher.dart';
import '../../widgets/exercise_thumb.dart';
import '../../widgets/pill.dart';
import '../exercise/exercise_dialog.dart';
import '../../../models/workout.dart';
import '../workouts/exercise_picker_sheet.dart';
import 'substitute_sheet.dart';

/// Treino gerado de um dia, com o motivo de cada escolha.
class DayDraftCard extends StatelessWidget {
  final int day;
  final DayDraft draft;
  const DayDraftCard({required this.day, required this.draft, super.key});

  @override
  Widget build(BuildContext context) {
    final planner = context.read<PlannerCubit>();
    final catalog = context.read<CatalogCubit>();
    final w = draft.workout;
    final exercises = [
      for (final it in w.items)
        if (catalog.byId(it.exerciseId) case final Exercise e) e,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weekdayFull[day - 1].toUpperCase(),
                        style: AppText.eyebrow(context.pal.muted),
                      ),
                      Text(
                        w.focus.label.toUpperCase(),
                        style: AppText.display(34),
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: context.pal.volt,
                    foregroundColor: context.pal.onVolt,
                  ),
                  tooltip: 'Adicionar exercício',
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => _addExercises(context, planner, w),
                ),
                IconButton(
                  tooltip: 'Gerar este dia de novo',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => planner.generateDay(day),
                ),
                IconButton(
                  tooltip: 'Remover dia',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => planner.removeDraft(day),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final label in workoutEquipment(exercises))
                    Pill(label, color: context.pal.muted),
                ],
              ),
            ),
            if (w.stretches.isNotEmpty || planner.state.profile.stretching) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ALONGAMENTOS',
                        style: AppText.eyebrow(context.pal.muted),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _addStretches(context, planner, w),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Adicionar'),
                    ),
                  ],
                ),
              ),
              for (final it in w.stretches)
                if (catalog.byId(it.exerciseId) case final Exercise e)
                  _Row(
                    key: ValueKey('$day-st-${e.id}'),
                    exercise: e,
                    prescription: '${it.sets}×${it.reps}s',
                    reason: draft.reasons[e.id],
                    onOpen: () => showExercise(context, e),
                    onSwap: () => showSubstitutes(
                      context,
                      day: day,
                      index: w.stretches.indexOf(it),
                      current: e,
                      stretch: true,
                    ),
                    onRemove: () => planner.removeStretch(day, e.id),
                  ),
            ],
            if (w.stretches.isNotEmpty || planner.state.profile.stretching)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 8, 4),
                child: Text(
                  'TREINO',
                  style: AppText.eyebrow(context.pal.muted),
                ),
              ),
            for (final (i, it) in w.items.indexed)
              if (catalog.byId(it.exerciseId) case final Exercise e)
                _Row(
                  key: ValueKey('$day-${e.id}'),
                  exercise: e,
                  prescription: e.isCardio
                      ? '${it.reps} min'
                      : '${it.sets}×${it.reps}',
                  reason: draft.reasons[e.id],
                  onOpen: () => showExercise(context, e),
                  onSwap: () =>
                      showSubstitutes(context, day: day, index: i, current: e),
                  onRemove: () => planner.removeItem(day, i),
                ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 8, 8),
              child: OutlinedButton.icon(
                onPressed: () => _addExercises(context, planner, w),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Adicionar exercício'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Abre o seletor para incluir (ou tirar) alongamentos do dia gerado.
Future<void> _addStretches(
  BuildContext context,
  PlannerCubit planner,
  Workout w,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => ExercisePickerSheet(
    stretch: true,
    focus: w.focus,
    chosen: {for (final i in w.stretches) i.exerciseId},
    onToggle: (e, add) => add
        ? planner.addStretch(w.weekday!, e)
        : planner.removeStretch(w.weekday!, e.id),
  ),
);

/// Abre o seletor para incluir (ou tirar) exercícios do dia gerado.
Future<void> _addExercises(
  BuildContext context,
  PlannerCubit planner,
  Workout w,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => ExercisePickerSheet(
    focus: w.focus,
    chosen: {for (final i in w.items) i.exerciseId},
    onToggle: (e, add) => add
        ? planner.addExercise(w.weekday!, e)
        : planner.removeExercise(w.weekday!, e.id),
  ),
);

class _Row extends StatelessWidget {
  final Exercise exercise;
  final String prescription;
  final String? reason;
  final VoidCallback onOpen, onRemove;
  final VoidCallback? onSwap;

  const _Row({
    super.key,
    required this.exercise,
    required this.prescription,
    required this.reason,
    required this.onOpen,
    this.onSwap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            ExerciseThumb(exercise, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exerciseNamePt(exercise.name),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${equipmentLabelOf(exercise)} · ${exercise.primary.map(muscleLabel).join(', ')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: p.muted),
                  ),
                  if (reason != null)
                    Text(
                      reason!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: p.text.withValues(alpha: .55),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              prescription,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            if (onSwap != null)
              IconButton(
                tooltip: 'Trocar exercício',
                icon: Icon(Icons.swap_horiz_rounded, color: p.accent),
                onPressed: onSwap,
              ),
            IconButton(
              tooltip: 'Remover',
              icon: Icon(Icons.close_rounded, color: p.muted),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
