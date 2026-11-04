import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/equipment/equipment_matcher.dart';
import '../../../models/exercise.dart';
import '../../../models/labels.dart';
import '../../../models/plan_item.dart';
import '../../../models/workout.dart';
import '../../../state/catalog_cubit.dart';
import '../../../state/nav_cubit.dart';
import '../../../state/planner_cubit.dart';
import '../../../state/workouts_cubit.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/page_body.dart';
import '../../widgets/pill.dart';
import '../../widgets/toast.dart';
import '../exercise/exercise_dialog.dart';
import 'confetti_painter.dart';
import 'done_banner.dart';
import 'finish_workout.dart';
import 'rest_timer.dart';
import 'ticket_row.dart';
import 'workout_editor_page.dart';

Future<void> openTicket(BuildContext context, Workout w) => Navigator.of(
  context,
).push(MaterialPageRoute(builder: (_) => WorkoutTicketPage(workout: w)));

/// Ficha do treino: checklist de exercícios, cargas e cronômetro de descanso.
class WorkoutTicketPage extends StatefulWidget {
  final Workout workout;
  const WorkoutTicketPage({required this.workout, super.key});

  @override
  State<WorkoutTicketPage> createState() => _WorkoutTicketPageState();
}

class _WorkoutTicketPageState extends State<WorkoutTicketPage>
    with SingleTickerProviderStateMixin {
  late final _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  final _scroll = ScrollController();

  Workout get w => widget.workout;
  bool get _complete => w.items.isNotEmpty && w.doneCount == w.items.length;

  @override
  void dispose() {
    _confetti.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Marca (ou desfaz) a série [index]; tocar na última marcada a desfaz.
  void _setTap(PlanItem it, int index) {
    setState(() => it.setsDone = it.setsDone == index + 1 ? index : index + 1);
    _changed();
  }

  /// Marca (ou desfaz) o exercício inteiro.
  void _toggleDone(PlanItem it) {
    setState(() => it.done = !it.done);
    _changed();
  }

  void _changed() {
    context.read<WorkoutsCubit>().touch();
    HapticFeedback.lightImpact();
    if (!_complete) return;
    HapticFeedback.heavyImpact();
    _confetti.forward(from: 0);
    _showEnd();
  }

  /// Leva até o aviso de treino concluído, depois que ele terminar de abrir.
  Future<void> _showEnd() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted || !_scroll.hasClients) return;
    await _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  Future<void> _editLoad(PlanItem it) async {
    final kg = await askNumber(
      context,
      title: 'Carga do exercício',
      label: 'Carga (kg)',
      initial: it.kg == null ? '' : '${it.kg}',
    );
    if (kg == null || !mounted) return;
    setState(() => it.kg = kg > 0 ? kg : null);
    context.read<WorkoutsCubit>().touch();
  }

  Future<void> _finish() async {
    final ok = await finishWorkout(context, w);
    if (!ok || !mounted) return;
    context.read<NavCubit>().go(AppTab.progress);
    showToast(context, 'Treino salvo no calendário!');
    Navigator.of(context).pop();
  }

  void _toggleStretch(PlanItem it) {
    setState(() => it.done = !it.done);
    context.read<WorkoutsCubit>().touch();
    HapticFeedback.lightImpact();
  }

  void _addStretches() {
    final list = context.read<PlannerCubit>().stretchesFor(w);
    if (list.isEmpty) {
      showToast(context, 'Nenhum alongamento disponível com seu equipamento.');
      return;
    }
    setState(() => w.stretches.addAll(list));
    context.read<WorkoutsCubit>().touch();
  }

  void _stretchSetTap(PlanItem it, int index) {
    setState(() => it.setsDone = it.setsDone == index + 1 ? index : index + 1);
    context.read<WorkoutsCubit>().touch();
    HapticFeedback.lightImpact();
  }

  void _reset() {
    setState(() {
      for (final i in [...w.items, ...w.stretches]) {
        i.setsDone = 0;
      }
    });
    context.read<WorkoutsCubit>().touch();
  }

  Future<void> _edit() async {
    await openWorkoutEditor(context, existing: w);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final catalog = context.read<CatalogCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ficha do treino'),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _edit,
          ),
          IconButton(
            tooltip: 'Reiniciar',
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: _reset,
          ),
        ],
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: contentMaxWidth - 300,
              ),
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                children: [
                  _Header(
                    workout: w,
                    equipment: workoutEquipment([
                      for (final i in w.items)
                        if (catalog.byId(i.exerciseId) case final Exercise e) e,
                    ]),
                  ),
                  const SizedBox(height: 16),
                  if (w.stretches.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OutlinedButton.icon(
                        onPressed: _addStretches,
                        icon: const Icon(Icons.self_improvement_rounded),
                        label: const Text('Gerar alongamentos do dia'),
                      ),
                    )
                  else ...[
                    _SectionLabel(
                      'Alongamentos',
                      '${w.stretches.where((s) => s.done).length}/${w.stretches.length}',
                    ),
                    for (final it in w.stretches)
                      if (catalog.byId(it.exerciseId) case final Exercise e)
                        TicketRow(
                          key: ValueKey('st-${it.exerciseId}'),
                          exercise: e,
                          item: it,
                          stretch: true,
                          onSetTap: (i) => _stretchSetTap(it, i),
                          onToggleDone: () => _toggleStretch(it),
                          onOpen: () => showExercise(context, e),
                          onEditLoad: () {},
                          onRest: () => showRestTimer(context, it.reps),
                        ),
                    _SectionLabel('Treino', '${w.doneCount}/${w.items.length}'),
                  ],
                  for (final it in w.items)
                    if (catalog.byId(it.exerciseId) case final Exercise e)
                      TicketRow(
                        key: ValueKey(it.exerciseId),
                        exercise: e,
                        item: it,
                        onSetTap: (i) => _setTap(it, i),
                        onToggleDone: () => _toggleDone(it),
                        onOpen: () => showExercise(context, e),
                        onEditLoad: () => _editLoad(it),
                        onRest: () => showRestTimer(context, it.restSec),
                      ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutBack,
                    child: _complete
                        ? DoneBanner(onFinish: _finish)
                        : const SizedBox(width: double.infinity),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confetti,
                builder: (_, _) => CustomPaint(
                  painter: ConfettiPainter(_confetti.value, [
                    ...p.tints,
                    p.highlight,
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Workout workout;
  final List<String> equipment;
  const _Header({required this.workout, required this.equipment});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final w = workout;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: p.volt,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            w.weekday == null
                ? 'TREINO'
                : 'TREINO · ${weekdayFull[w.weekday! - 1].toUpperCase()}',
            style: AppText.eyebrow(p.onVolt.withValues(alpha: .65)),
          ),
          const SizedBox(height: 6),
          Text(
            w.focus.label.toUpperCase(),
            style: AppText.display(60, color: p.onVolt),
          ),
          const SizedBox(height: 4),
          Text(
            '${w.items.length} exercícios · ~${w.estimatedMinutes} min'
            '${w.stretches.isEmpty ? '' : ' · ${w.stretches.length} alongamentos'}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: p.onVolt.withValues(alpha: .8),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'EQUIPAMENTOS DO DIA',
            style: AppText.eyebrow(p.onVolt.withValues(alpha: .6)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final e in equipment) Pill(e, color: p.onVolt)],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: w.progress),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 10,
                      color: p.onVolt,
                      backgroundColor: p.onVolt.withValues(alpha: .15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${w.doneCount}/${w.items.length}',
                style: AppText.display(26, color: p.onVolt),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Título que separa as seções da ficha (alongamentos / treino).
class _SectionLabel extends StatelessWidget {
  final String title, count;
  const _SectionLabel(this.title, this.count);

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title.toUpperCase(), style: AppText.display(28)),
          ),
          Text(
            count,
            style: TextStyle(fontWeight: FontWeight.w800, color: p.muted),
          ),
        ],
      ),
    );
  }
}
