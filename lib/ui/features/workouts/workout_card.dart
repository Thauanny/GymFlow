import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../models/workout.dart';
import '../../../state/workouts_cubit.dart';
import '../../widgets/app_card.dart';
import '../../widgets/dialogs.dart';
import 'share_sheet.dart';
import 'workout_editor_page.dart';
import 'workout_ticket_page.dart';

class WorkoutCard extends StatelessWidget {
  final Workout workout;
  const WorkoutCard(this.workout, {super.key});

  Future<void> _delete(BuildContext context) async {
    final ok = await confirmDialog(
      context,
      title: 'Excluir treino?',
      message: '"${workout.name}" será removido.',
      confirm: 'Excluir',
    );
    if (ok && context.mounted) context.read<WorkoutsCubit>().delete(workout);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final w = workout;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () => openTicket(context, w),
        radius: 26,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: p.volt,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(w.focus.icon, color: p.onVolt),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w.focus.label.toUpperCase(),
                        style: AppText.display(30),
                      ),
                      Text(
                        '${w.items.length} exercícios · ~${w.estimatedMinutes} min'
                        '${w.stretches.isEmpty ? '' : ' · alongamento'}',
                        style: TextStyle(fontSize: 13, color: p.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Compartilhar no WhatsApp',
                  icon: const Icon(Icons.share_rounded),
                  onPressed: () => showShareSheet(
                    context,
                    title: 'Compartilhar ${w.focus.label}',
                    text: workoutShareText(context, w),
                  ),
                ),
                IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => openWorkoutEditor(context, existing: w),
                ),
                IconButton(
                  tooltip: 'Excluir',
                  icon: Icon(Icons.delete_outline_rounded, color: p.muted),
                  onPressed: () => _delete(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: w.progress,
                      minHeight: 8,
                      color: p.highlight,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${w.doneCount}/${w.items.length}',
                  style: TextStyle(fontWeight: FontWeight.w700, color: p.muted),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => openTicket(context, w),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(w.doneCount > 0 ? 'Continuar' : 'Começar'),
            ),
          ],
        ),
      ),
    );
  }
}
