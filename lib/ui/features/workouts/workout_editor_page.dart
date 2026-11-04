import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/day_focus.dart';
import '../../../models/labels.dart';
import '../../../models/plan_item.dart';
import '../../../models/workout.dart';
import '../../../state/catalog_cubit.dart';
import '../../../state/workouts_cubit.dart';
import '../../widgets/page_body.dart';
import '../../widgets/section_title.dart';
import '../../../domain/training/stretch_planner.dart';
import 'editor_item_row.dart';
import 'exercise_picker_sheet.dart';

/// Abre o editor (criar do zero ou editar). Retorna o treino salvo, ou null se cancelado.
Future<Workout?> openWorkoutEditor(
  BuildContext context, {
  Workout? existing,
  int? weekday,
  String? focusId,
  String? name,
}) => Navigator.of(context).push<Workout>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => WorkoutEditorPage(
      existing: existing,
      weekday: weekday,
      focusId: focusId,
      name: name,
    ),
  ),
);

class WorkoutEditorPage extends StatefulWidget {
  final Workout? existing;
  final int? weekday;
  final String? focusId, name;
  const WorkoutEditorPage({
    this.existing,
    this.weekday,
    this.focusId,
    this.name,
    super.key,
  });

  @override
  State<WorkoutEditorPage> createState() => _WorkoutEditorPageState();
}

class _WorkoutEditorPageState extends State<WorkoutEditorPage> {
  late final _name = TextEditingController(
    text: widget.existing?.name ?? widget.name ?? '',
  );
  late String _focus = widget.existing?.day ?? widget.focusId ?? 'full';
  late int? _weekday = widget.existing?.weekday ?? widget.weekday;
  late final List<PlanItem> _stretches = [
    for (final i in widget.existing?.stretches ?? <PlanItem>[]) i.copy(),
  ];
  late final List<PlanItem> _items = [
    for (final i in widget.existing?.items ?? <PlanItem>[]) i.copy(),
  ];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final focus = focusById(_focus);
    final name = _name.text.trim().isEmpty
        ? 'Treino ${focus.label}'
        : _name.text.trim();
    final w =
        widget.existing ??
        Workout(DateTime.now().millisecondsSinceEpoch.toString(), name, []);
    w
      ..name = name
      ..day = _focus
      ..weekday = _weekday
      ..items.clear()
      ..items.addAll(_items)
      ..stretches.clear()
      ..stretches.addAll(_stretches);
    context.read<WorkoutsCubit>().save(w);
    Navigator.of(context).pop(w);
  }

  Future<void> _addStretches() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ExercisePickerSheet(
      stretch: true,
      focus: focusById(_focus),
      chosen: {for (final i in _stretches) i.exerciseId},
      onToggle: (e, add) => setState(() {
        add
            ? _stretches.add(
                PlanItem(e.id, stretchSets, stretchHoldSec, restSec: 0),
              )
            : _stretches.removeWhere((i) => i.exerciseId == e.id);
      }),
    ),
  );

  Future<void> _addExercises() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ExercisePickerSheet(
      focus: focusById(_focus),
      chosen: {for (final i in _items) i.exerciseId},
      onToggle: (e, add) => setState(() {
        add
            ? _items.add(
                PlanItem(e.id, e.isCardio ? 1 : 3, e.isCardio ? 20 : 10),
              )
            : _items.removeWhere((i) => i.exerciseId == e.id);
      }),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final catalog = context.read<CatalogCubit>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Montar treino' : 'Editar treino',
        ),
      ),
      body: PageBody(
        title: '',
        bottom: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton.icon(
              onPressed: _items.isEmpty && _stretches.isEmpty ? null : _save,
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('Salvar treino'),
            ),
          ),
        ),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Nome do treino',
              hintText: 'Ex.: Costas e bíceps',
              prefixIcon: Icon(Icons.edit_outlined),
            ),
          ),
          const SectionTitle('Foco do dia'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in dayFocuses.values)
                ChoiceChip(
                  avatar: Icon(f.icon, size: 18),
                  label: Text(f.label),
                  selected: _focus == f.id,
                  onSelected: (_) => setState(() => _focus = f.id),
                ),
            ],
          ),
          const SectionTitle('Dia da semana'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < 7; i++)
                ChoiceChip(
                  label: Text(weekdayNames[i]),
                  selected: _weekday == i + 1,
                  onSelected: (v) =>
                      setState(() => _weekday = v ? i + 1 : null),
                ),
            ],
          ),
          SectionTitle(
            'Alongamentos (${_stretches.length})',
            trailing: FilledButton.tonalIcon(
              onPressed: _addStretches,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar'),
            ),
          ),
          if (_stretches.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('Opcional. Toque em "Adicionar" para alongar.'),
              ),
            )
          else
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorder: (a, b) => setState(() {
                if (b > a) b--;
                _stretches.insert(b, _stretches.removeAt(a));
              }),
              children: [
                for (final (i, it) in _stretches.indexed)
                  EditorItemRow(
                    key: ValueKey('st-${it.exerciseId}-$i'),
                    index: i,
                    stretch: true,
                    exercise: catalog.byId(it.exerciseId),
                    item: it,
                    onRemove: () => setState(() => _stretches.removeAt(i)),
                    onChanged: () => setState(() {}),
                  ),
              ],
            ),
          SectionTitle(
            'Exercícios (${_items.length})',
            trailing: FilledButton.tonalIcon(
              onPressed: _addExercises,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar'),
            ),
          ),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('Nenhum exercício ainda. Toque em "Adicionar".'),
              ),
            )
          else
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorder: (a, b) => setState(() {
                if (b > a) b--;
                _items.insert(b, _items.removeAt(a));
              }),
              children: [
                for (final (i, it) in _items.indexed)
                  EditorItemRow(
                    key: ValueKey('${it.exerciseId}-$i'),
                    index: i,
                    exercise: catalog.byId(it.exerciseId),
                    item: it,
                    onRemove: () => setState(() => _items.removeAt(i)),
                    onChanged: () => setState(() {}),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
