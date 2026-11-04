import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format.dart';
import '../../../data/translation/pt_names.dart';
import '../../../models/archived_plan.dart';
import '../../../models/labels.dart';
import '../../../models/workout.dart';
import '../../../state/catalog_cubit.dart';
import '../../../state/workouts_cubit.dart';
import '../../widgets/app_card.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/section_title.dart';
import '../../widgets/toast.dart';

const _initialShown = 3;

/// Planos que foram trocados ou evoluídos, para consultar e restaurar.
class PlanHistorySection extends StatefulWidget {
  const PlanHistorySection({super.key});

  @override
  State<PlanHistorySection> createState() => _PlanHistorySectionState();
}

class _PlanHistorySectionState extends State<PlanHistorySection> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutsCubit, WorkoutsState>(
      builder: (context, s) {
        if (s.archive.isEmpty) return const SizedBox.shrink();
        final shown = _all ? s.archive : s.archive.take(_initialShown).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle(
              'Planos anteriores',
              hint:
                  'Treinos que você trocou ou evoluiu. Toque para ver ou restaurar; segure para excluir.',
            ),
            for (final a in shown) _ArchiveCard(a),
            if (s.archive.length > _initialShown)
              TextButton(
                onPressed: () => setState(() => _all = !_all),
                child: Text(
                  _all ? 'Ver menos' : 'Ver todos (${s.archive.length})',
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  final ArchivedPlan plan;
  const _ArchiveCard(this.plan);

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final days = (plan.weekdays.toList()..sort())
        .map((d) => weekdayNames[d - 1])
        .join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () => showArchiveSheet(context, plan),
        onLongPress: () =>
            _confirmDeletePlan(context, context.read<WorkoutsCubit>(), plan),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: p.cardAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.history_rounded, color: p.muted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${formatDate(plan.date)} · ${plan.workouts.length} treino(s)'
                    '${days.isEmpty ? '' : ' · $days'}',
                    style: TextStyle(fontSize: 12.5, color: p.muted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.muted),
          ],
        ),
      ),
    );
  }
}

/// Pede confirmação e apaga o plano do histórico. Retorna se apagou.
Future<bool> _confirmDeletePlan(
  BuildContext context,
  WorkoutsCubit cubit,
  ArchivedPlan plan,
) async {
  final ok = await confirmDialog(
    context,
    title: 'Excluir do histórico?',
    message: 'Este plano antigo será apagado de vez.',
    confirm: 'Excluir',
  );
  if (ok) cubit.deleteArchived(plan.id);
  return ok;
}

/// Detalhe de um plano do histórico, com os botões de restaurar e excluir.
Future<void> showArchiveSheet(BuildContext context, ArchivedPlan plan) {
  final cubit = context.read<WorkoutsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetCtx) => BlocBuilder<WorkoutsCubit, WorkoutsState>(
      bloc: cubit,
      builder: (_, s) {
        // reflete os treinos já apagados de dentro do plano
        final current =
            s.archive.where((a) => a.id == plan.id).firstOrNull ?? plan;
        return _ArchiveSheet(
          plan: current,
          onRestore: () {
            cubit.restoreArchived(current);
            Navigator.of(sheetCtx).pop();
            showToast(context, 'Plano restaurado');
          },
          onDelete: () async {
            final ok = await _confirmDeletePlan(sheetCtx, cubit, current);
            if (ok && sheetCtx.mounted) Navigator.of(sheetCtx).pop();
          },
          onDeleteWorkout: (w) async {
            final ok = await confirmDialog(
              sheetCtx,
              title: 'Excluir treino?',
              message: 'Este treino será apagado deste plano antigo.',
              confirm: 'Excluir',
            );
            if (!ok || !sheetCtx.mounted) return;
            cubit.deleteArchivedWorkout(current.id, w.id);
            if (current.workouts.length <= 1) Navigator.of(sheetCtx).pop();
          },
        );
      },
    ),
  );
}

class _ArchiveSheet extends StatelessWidget {
  final ArchivedPlan plan;
  final VoidCallback onRestore;
  final Future<void> Function() onDelete;
  final Future<void> Function(Workout) onDeleteWorkout;
  const _ArchiveSheet({
    required this.plan,
    required this.onRestore,
    required this.onDelete,
    required this.onDeleteWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final catalog = context.read<CatalogCubit>();
    final workouts = [...plan.workouts]
      ..sort((a, b) => (a.weekday ?? 8).compareTo(b.weekday ?? 8));
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        shrinkWrap: true,
        children: [
          Text(plan.label.toUpperCase(), style: AppText.display(34)),
          Text(
            'Guardado em ${formatDate(plan.date)}',
            style: TextStyle(color: p.muted),
          ),
          const SizedBox(height: 16),
          for (final w in workouts)
            _WorkoutSummary(w, catalog, onDelete: () => onDeleteWorkout(w)),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onRestore,
            icon: const Icon(Icons.restore_rounded),
            label: const Text('Restaurar este plano'),
          ),
          TextButton.icon(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline_rounded, color: p.danger),
            label: Text(
              'Excluir plano do histórico',
              style: TextStyle(color: p.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutSummary extends StatelessWidget {
  final Workout workout;
  final CatalogCubit catalog;
  final VoidCallback onDelete;
  const _WorkoutSummary(this.workout, this.catalog, {required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final w = workout;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        onLongPress: onDelete,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${w.weekday == null ? 'SEM DIA' : weekdayFull[w.weekday! - 1].toUpperCase()}'
                    ' · ${w.focus.label.toUpperCase()}',
                    style: AppText.display(22),
                  ),
                ),
                IconButton(
                  tooltip: 'Excluir treino',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.delete_outline_rounded, color: p.danger),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final i in w.items)
              if (catalog.byId(i.exerciseId) case final e?)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          exerciseNamePt(e.name),
                          style: const TextStyle(fontSize: 13.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        [
                          e.isCardio ? '${i.reps} min' : '${i.sets}×${i.reps}',
                          if (i.kg != null) '${i.kg} kg',
                        ].join(' · '),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: p.muted,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
