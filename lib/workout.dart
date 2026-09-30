import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'equipment.dart';
import 'main.dart';
import 'models.dart';
import 'pages.dart';
import 'state.dart';

const _green = Color(0xFF7E6BB0);
const _purple = Color(0xFF7E6BB0);

/// Sugere o tipo de dia conforme os músculos dos exercícios.
String guessDay(Iterable<Exercise> es) {
  if (es.isEmpty) return 'mixed';
  if (es.every((e) => e.category == 'cardio')) return 'cardio';
  const lower = {
    'quadriceps',
    'hamstrings',
    'glutes',
    'calves',
    'abductors',
    'adductors',
  };
  const upper = {
    'chest',
    'shoulders',
    'lats',
    'biceps',
    'triceps',
    'middle back',
    'traps',
    'forearms',
    'lower back',
  };
  var l = 0, u = 0;
  for (final e in es) {
    if (e.primary.isEmpty) continue;
    if (lower.contains(e.primary.first)) l++;
    if (upper.contains(e.primary.first)) u++;
  }
  if (l > 0 && u == 0) return 'lower1';
  if (u > 0 && l == 0) return 'upper1';
  return 'mixed';
}

/// Abre o editor (criar do zero, revisar sugestão da IA ou editar treino salvo).
/// Retorna o treino salvo, ou nulo se o usuário cancelou.
Future<Workout?> showWorkoutEditor(
  BuildContext context,
  AppState state, {
  Workout? existing,
  List<PlanItem>? initialItems,
  String? name,
  int? weekday,
  String? initialDay,
  bool draft = false,
  bool exercisesOnly = false,
}) {
  return Navigator.of(context).push<Workout>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _WorkoutEditor(
        state: state,
        existing: existing,
        initialItems: initialItems,
        initialName: name,
        initialWeekday: weekday,
        initialDay: initialDay,
        draft: draft,
        exercisesOnly: exercisesOnly,
      ),
    ),
  );
}

Future<void> openTicket(BuildContext context, AppState state, Workout w) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => WorkoutTicketPage(state: state, workout: w),
    ),
  );
}

Future<bool> finishWorkout(
  BuildContext context,
  AppState state,
  Workout w,
) async {
  final c = TextEditingController(text: '45');
  final min = await showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Registrar treino'),
      content: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Duração (min)'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, int.tryParse(c.text) ?? 0),
          child: const Text('Registrar'),
        ),
      ],
    ),
  );
  c.dispose();
  if (min == null) return false;
  state.addLog(LogEntry(DateTime.now(), w.name, w.items.length, min));
  for (final i in w.items) {
    i.done = false;
  }
  state.touch();
  return true;
}

// ------------------------------------------------------------------- Editor

class _WorkoutEditor extends StatefulWidget {
  final AppState state;
  final Workout? existing;
  final List<PlanItem>? initialItems;
  final String? initialName;
  final int? initialWeekday;
  final String? initialDay;
  final bool draft;
  final bool exercisesOnly;
  const _WorkoutEditor({
    required this.state,
    this.existing,
    this.initialItems,
    this.initialName,
    this.initialWeekday,
    this.initialDay,
    this.draft = false,
    this.exercisesOnly = false,
  });

  @override
  State<_WorkoutEditor> createState() => _WorkoutEditorState();
}

class _WorkoutEditorState extends State<_WorkoutEditor> {
  late final TextEditingController nameCtl;
  late String day;
  int? weekday;
  late final List<PlanItem> items;

  @override
  void initState() {
    super.initState();
    final w = widget.existing;
    weekday = w?.weekday ?? widget.initialWeekday;
    nameCtl = TextEditingController(text: w?.name ?? widget.initialName ?? '');
    items = [
      for (final i in (w?.items ?? widget.initialItems ?? <PlanItem>[]))
        PlanItem(i.exerciseId, i.sets, i.reps, done: i.done),
    ];
    day =
        w?.day ??
        widget.initialDay ??
        guessDay([
          for (final i in items)
            if (widget.state.byId(i.exerciseId) case final e?) e,
        ]);
  }

  @override
  void dispose() {
    nameCtl.dispose();
    super.dispose();
  }

  void save() {
    final s = widget.state;
    final name = nameCtl.text.trim().isEmpty
        ? 'Treino ${dayTypes[day]!.$1}'
        : nameCtl.text.trim();
    final w =
        widget.existing ??
        Workout(DateTime.now().millisecondsSinceEpoch.toString(), name, []);
    w
      ..name = name
      ..day = day
      ..weekday = weekday
      ..items.clear()
      ..items.addAll(items);
    if (widget.draft && weekday != null) {
      s.setDraft(w);
    } else {
      s.saveWorkout(w);
    }
    Navigator.of(context).pop(w);
  }

  Future<void> addExercises() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _ExercisePicker(
        state: widget.state,
        day: day,
        chosen: {for (final i in items) i.exerciseId},
        onToggle: (e, add) => setState(() {
          if (add) {
            items.add(PlanItem(e.id, 3, 10));
          } else {
            items.removeWhere((i) => i.exerciseId == e.id);
          }
        }),
      ),
    );
  }

  Widget _stepper(IconData icon, VoidCallback onTap) => SizedBox(
    width: 40,
    height: 40,
    child: IconButton(
      padding: EdgeInsets.zero,
      icon: Icon(icon, size: 20),
      onPressed: onTap,
    ),
  );

  Widget _row(int index, PlanItem it) {
    final e = widget.state.byId(it.exerciseId);
    final eq = e == null ? null : itemForExercise(e);
    return Card(
      key: ValueKey('${it.exerciseId}-$index'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Column(
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.drag_indicator, color: Colors.black38),
                  ),
                ),
                if (e != null) ...[
                  exerciseThumb(widget.state, e, 48),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e == null ? it.exerciseId : exerciseNamePt(e.name),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        e == null
                            ? ''
                            : '${e.primary.map(muscleLabel).join(', ')} • ${eq?.label ?? equipLabel(e.equipKey)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: ink.withValues(alpha: .6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remover',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => items.removeAt(index)),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Séries'),
                _stepper(
                  Icons.remove_circle_outline,
                  () => setState(() => it.sets = math.max(1, it.sets - 1)),
                ),
                Text(
                  '${it.sets}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                _stepper(
                  Icons.add_circle_outline,
                  () => setState(() => it.sets++),
                ),
                const SizedBox(width: 8),
                const Text('Reps'),
                _stepper(
                  Icons.remove_circle_outline,
                  () => setState(() => it.reps = math.max(1, it.reps - 1)),
                ),
                Text(
                  '${it.reps}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                _stepper(
                  Icons.add_circle_outline,
                  () => setState(() => it.reps++),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Montar treino' : 'Editar treino',
        ),
        backgroundColor: Colors.white,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!widget.exercisesOnly) ...[
              TextField(
                controller: nameCtl,
                decoration: const InputDecoration(
                  labelText: 'Nome do treino',
                  hintText: 'Ex.: Costas e bíceps',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Dia do treino',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in dayTypes.entries)
                    ChoiceChip(
                      avatar: Icon(d.value.$2, size: 18),
                      label: Text(d.value.$1),
                      selected: day == d.key,
                      selectedColor: lilac,
                      onSelected: (_) => setState(() => day = d.key),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Dia da semana',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < 7; i++)
                    ChoiceChip(
                      label: Text(weekdayNames[i]),
                      selected: weekday == i + 1,
                      selectedColor: sky,
                      onSelected: (v) =>
                          setState(() => weekday = v ? i + 1 : null),
                    ),
                ],
              ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Exercícios (${items.length})',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: addExercises,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ink.withValues(alpha: .15)),
                  ),
                  child: const Text(
                    'Nenhum exercício ainda. Toque em "Adicionar".',
                  ),
                )
              else
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorder: (a, b) => setState(() {
                    if (b > a) b--;
                    items.insert(b, items.removeAt(a));
                  }),
                  children: [for (final (i, it) in items.indexed) _row(i, it)],
                ),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: items.isEmpty ? null : save,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('Salvar treino'),
          ),
        ),
      ),
    );
  }
}

class _ExercisePicker extends StatefulWidget {
  final AppState state;
  final String day;
  final Set<String> chosen;
  final void Function(Exercise, bool add) onToggle;
  const _ExercisePicker({
    required this.state,
    required this.day,
    required this.chosen,
    required this.onToggle,
  });

  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
  String q = '';
  String? muscle;
  late bool mine = widget.state.available.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final day = widget.day;
    bool dayOk(Exercise e) {
      if (day == 'cardio') return e.category == 'cardio';
      if (day == 'mixed') return true;
      return e.category != 'cardio' &&
          guessDay([e]).startsWith(day.substring(0, 5));
    }

    final base = (mine ? s.available : s.exercises).where(dayOk).toList();
    final muscleOptions = {for (final e in base) ...e.primary};
    final list = base.where((e) {
      if (muscle == 'cardio') {
        if (e.category != 'cardio') return false;
      } else if (muscle != null && !e.primary.contains(muscle)) {
        return false;
      }
      final ql = q.toLowerCase();
      return q.isEmpty ||
          e.name.toLowerCase().contains(ql) ||
          (itemForExercise(e)?.label ?? equipLabel(e.equipKey))
              .toLowerCase()
              .contains(ql) ||
          e.primary.any((m) => muscleLabel(m).toLowerCase().contains(ql));
    }).toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => q = v),
              decoration: const InputDecoration(
                hintText: 'Buscar por aparelho ou músculo',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                FilterChip(
                  label: const Text('Só meus equipamentos'),
                  selected: mine,
                  selectedColor: sky,
                  onSelected: (v) => setState(() => mine = v),
                ),
                for (final m in [
                  if (day == 'cardio' || day == 'mixed') 'cardio',
                  ...muscleNames.keys.where(muscleOptions.contains),
                ])
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(m == 'cardio' ? 'Cardio' : muscleLabel(m)),
                      selected: muscle == m,
                      selectedColor: mint,
                      onSelected: (v) => setState(() => muscle = v ? m : null),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final e = list[i];
                final on = widget.chosen.contains(e.id);
                return ListTile(
                  onTap: () => setState(() {
                    on ? widget.chosen.remove(e.id) : widget.chosen.add(e.id);
                    widget.onToggle(e, !on);
                  }),
                  leading: exerciseThumb(s, e, 52),
                  title: Text(
                    exerciseNamePt(e.name),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${e.primary.map(muscleLabel).join(', ')} • ${itemForExercise(e)?.label ?? equipLabel(e.equipKey)}',
                  ),
                  trailing: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      on ? Icons.check_circle : Icons.add_circle_outline,
                      key: ValueKey(on),
                      color: on ? _green : null,
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('Concluir (${widget.chosen.length} selecionados)'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- Ficha/ticket

class WorkoutTicketPage extends StatefulWidget {
  final AppState state;
  final Workout workout;
  const WorkoutTicketPage({
    required this.state,
    required this.workout,
    super.key,
  });

  @override
  State<WorkoutTicketPage> createState() => _WorkoutTicketPageState();
}

class _WorkoutTicketPageState extends State<WorkoutTicketPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  Workout get w => widget.workout;
  bool get complete => w.items.isNotEmpty && w.doneCount == w.items.length;

  @override
  void dispose() {
    confetti.dispose();
    super.dispose();
  }

  void toggle(PlanItem it) {
    setState(() => it.done = !it.done);
    widget.state.touch();
    HapticFeedback.lightImpact();
    if (complete) {
      HapticFeedback.heavyImpact();
      confetti.forward(from: 0);
    }
  }

  Future<void> finish() async {
    final ok = await finishWorkout(context, widget.state, w);
    if (ok && mounted) {
      showToast(context, 'Treino registrado. Bom descanso!');
      Navigator.of(context).pop();
    }
  }

  void reset() {
    setState(() {
      for (final i in w.items) {
        i.done = false;
      }
    });
    widget.state.touch();
  }

  Future<void> edit() async {
    await showWorkoutEditor(context, widget.state, existing: w);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final day = dayTypes[w.day] ?? dayTypes['mixed']!;
    final equips = <String>{};
    for (final i in w.items) {
      final e = s.byId(i.exerciseId);
      if (e != null)
        equips.add((itemForExercise(e)?.label) ?? equipLabel(e.equipKey));
    }
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final progress = w.items.isEmpty ? 0.0 : w.doneCount / w.items.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ficha do treino'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: edit,
          ),
          IconButton(
            tooltip: 'Reiniciar',
            icon: const Icon(Icons.restart_alt),
            onPressed: reset,
          ),
        ],
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: ink.withValues(alpha: .08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Chip(
                                avatar: Icon(day.$2, size: 18),
                                label: Text(
                                  w.weekday == null
                                      ? day.$1
                                      : '${day.$1} \u2022 ${weekdayNames[w.weekday! - 1]}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                backgroundColor: lilac,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                w.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: ink,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween(end: progress),
                                        duration: const Duration(
                                          milliseconds: 500,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        builder: (_, v, _) =>
                                            LinearProgressIndicator(
                                              value: v,
                                              minHeight: 10,
                                              backgroundColor: lilac.withValues(
                                                alpha: .4,
                                              ),
                                              color: _green,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${w.doneCount}/${w.items.length}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Equipamentos do dia',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ink.withValues(alpha: .6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final (i, e) in equips.indexed)
                                    Chip(
                                      label: Text(
                                        e,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      backgroundColor: [
                                        mint,
                                        peach,
                                        sky,
                                        rose,
                                        lilac,
                                      ][i % 5].withValues(alpha: .6),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _TearLine(bg),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                          child: Column(
                            children: [
                              for (final it in w.items)
                                if (s.byId(it.exerciseId) case final e?)
                                  _TicketRow(
                                    exercise: e,
                                    item: it,
                                    thumb: exerciseThumb(s, e, 44),
                                    equipLabelText: exerciseNamePt(e.name),
                                    onToggle: () => toggle(it),
                                    onOpen: () => showExercise(context, e),
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutBack,
                    child: complete
                        ? _DoneBanner(onFinish: finish)
                        : const SizedBox(width: double.infinity),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: confetti,
                builder: (_, _) =>
                    CustomPaint(painter: _ConfettiPainter(confetti.value)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  final Exercise exercise;
  final PlanItem item;
  final Widget thumb;
  final String equipLabelText;
  final VoidCallback onToggle, onOpen;
  const _TicketRow({
    required this.exercise,
    required this.item,
    required this.thumb,
    required this.equipLabelText,
    required this.onToggle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final done = item.done;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: done ? mint.withValues(alpha: .35) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _AnimatedCheck(checked: done, onTap: onToggle),
          thumb,
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: done ? ink.withValues(alpha: .5) : ink,
                        decoration: done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                      child: Text(equipLabelText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exercise.primary.map(muscleLabel).join(', '),
                      style: TextStyle(
                        fontSize: 12,
                        color: ink.withValues(alpha: .6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              '${item.sets}×${item.reps}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedCheck extends StatelessWidget {
  final bool checked;
  final VoidCallback onTap;
  const _AnimatedCheck({required this.checked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: checked ? _green : Colors.white,
              border: Border.all(
                color: checked ? _green : ink.withValues(alpha: .3),
                width: 2,
              ),
              boxShadow: checked
                  ? [
                      BoxShadow(
                        color: _green.withValues(alpha: .45),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : const [],
            ),
            child: AnimatedScale(
              scale: checked ? 1 : 0,
              duration: const Duration(milliseconds: 450),
              curve: Curves.elasticOut,
              child: const Icon(Icons.check, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

class _TearLine extends StatelessWidget {
  final Color bg;
  const _TearLine(this.bg);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: -12,
            child: CircleAvatar(radius: 12, backgroundColor: bg),
          ),
          Positioned(
            right: -12,
            child: CircleAvatar(radius: 12, backgroundColor: bg),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LayoutBuilder(
              builder: (_, c) {
                final n = (c.maxWidth / 12).floor();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < n; i++)
                      Container(
                        width: 6,
                        height: 2,
                        color: ink.withValues(alpha: .18),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneBanner extends StatelessWidget {
  final VoidCallback onFinish;
  const _DoneBanner({required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [mint, sky]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: const Icon(
              Icons.emoji_events_rounded,
              size: 64,
              color: Color(0xFFB5651D),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Treino concluído!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Todos os equipamentos foram feitos.',
            style: TextStyle(color: ink.withValues(alpha: .7)),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: onFinish,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Registrar treino'),
          ),
        ],
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  _ConfettiPainter(this.t);

  static const _colors = [mint, lilac, peach, sky, rose, _purple, _green];
  static final _rnd = math.Random(7);
  static final _parts = [
    for (var i = 0; i < 60; i++)
      (
        x: _rnd.nextDouble(),
        vx: (_rnd.nextDouble() - .5) * 320,
        vy: -200 - _rnd.nextDouble() * 320,
        size: 5 + _rnd.nextDouble() * 6,
        color: _colors[i % _colors.length],
        rot: _rnd.nextDouble() * math.pi,
      ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final sec = t * 2.2;
    for (final p in _parts) {
      final x = p.x * size.width + p.vx * sec;
      final y = size.height * .55 + p.vy * sec + 520 * sec * sec;
      final paint = Paint()
        ..color = p.color.withValues(alpha: (1 - t).clamp(0, 1));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rot + sec * 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 1.6,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
