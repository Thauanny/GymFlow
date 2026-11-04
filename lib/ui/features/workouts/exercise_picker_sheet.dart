import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/equipment/equipment_matcher.dart';
import '../../../data/translation/pt_names.dart';
import '../../../models/day_focus.dart';
import '../../../models/exercise.dart';
import '../../../models/labels.dart';
import '../../../state/catalog_cubit.dart';
import '../../../state/equipment_cubit.dart';
import '../../widgets/exercise_thumb.dart';

/// Escolha de exercícios para o treino (busca, filtro por músculo e "meus equipamentos").
class ExercisePickerSheet extends StatefulWidget {
  final DayFocus focus;
  final Set<String> chosen;
  final void Function(Exercise exercise, bool add) onToggle;

  /// Escolhe alongamentos (e só eles); sem isso, só exercícios de treino.
  final bool stretch;

  const ExercisePickerSheet({
    required this.focus,
    required this.chosen,
    required this.onToggle,
    this.stretch = false,
    super.key,
  });

  @override
  State<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<ExercisePickerSheet> {
  String _query = '';
  String? _muscle;
  bool _onlyFocus = true; // limita aos músculos do foco do dia
  late bool _mine =
      widget.stretch ||
      context.read<EquipmentCubit>().state.available.isNotEmpty;

  bool _matchesFocus(Exercise e) {
    final f = widget.focus;
    if (widget.stretch) {
      // Dia de cardio: alongar as pernas.
      final muscles = f.isCardio ? dayFocuses['legs']!.muscles : f.muscles;
      return f.isFullBody ||
          !_onlyFocus ||
          e.primary.any(muscles.contains) ||
          (e.primary.contains('lower back') && muscles.contains('abdominals'));
    }
    if (e.category == 'stretching') return false;
    if (f.isCardio) return e.isCardio;
    if (f.isFullBody || !_onlyFocus) return true;
    return !e.isCardio && e.primary.any(f.muscles.contains);
  }

  bool _matchesQuery(Exercise e) {
    final q = _query.toLowerCase();
    if (q.isEmpty) return true;
    return e.name.toLowerCase().contains(q) ||
        exerciseNamePt(e.name).toLowerCase().contains(q) ||
        e.primary.any((m) => muscleLabel(m).toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final all = context.read<CatalogCubit>().state.exercises;
    final equip = context.read<EquipmentCubit>();
    final pool = widget.stretch
        ? (_mine
              ? equip.stretches
              : [
                  for (final e in all)
                    if (e.category == 'stretching') e,
                ])
        : (_mine ? equip.state.available : all);
    final base = pool.where(_matchesFocus).toList();
    final muscles = {for (final e in base) ...e.primary};
    final list = base
        .where(
          (e) =>
              (_muscle == null || e.primary.contains(_muscle)) &&
              _matchesQuery(e),
        )
        .toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: widget.stretch
                    ? 'Buscar alongamento ou músculo'
                    : 'Buscar exercício ou músculo',
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                if (!widget.focus.isFullBody && !widget.focus.isCardio)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text('Só ${widget.focus.label.toLowerCase()}'),
                      selected: _onlyFocus,
                      onSelected: (v) => setState(() {
                        _onlyFocus = v;
                        _muscle = null;
                      }),
                    ),
                  ),
                FilterChip(
                  label: const Text('Só meus equipamentos'),
                  selected: _mine,
                  onSelected: (v) => setState(() => _mine = v),
                ),
                for (final m in muscleNames.keys.where(muscles.contains))
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(muscleLabel(m)),
                      selected: _muscle == m,
                      onSelected: (v) => setState(() => _muscle = v ? m : null),
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
                  leading: ExerciseThumb(e, size: 48),
                  title: Text(
                    exerciseNamePt(e.name),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${e.primary.map(muscleLabel).join(', ')} · ${itemForExercise(e)?.label ?? equipLabel(e.equipKey)}',
                    style: TextStyle(color: p.muted),
                  ),
                  trailing: Icon(
                    on
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_outline_rounded,
                    color: on ? p.highlight : p.muted,
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
