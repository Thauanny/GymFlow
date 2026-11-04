import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/translation/pt_names.dart';
import '../../../models/exercise.dart';
import '../../../models/labels.dart';
import '../../../models/plan_item.dart';
import '../../widgets/app_card.dart';
import '../../widgets/exercise_thumb.dart';

/// Linha do editor: exercício com séries e repetições ajustáveis.
class EditorItemRow extends StatelessWidget {
  final int index;
  final Exercise? exercise;
  final PlanItem item;
  final VoidCallback onRemove, onChanged;

  const EditorItemRow({
    required this.index,
    required this.exercise,
    required this.item,
    required this.onRemove,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final e = exercise;
    final isCardio = e?.isCardio ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Column(
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(Icons.drag_indicator_rounded, color: p.muted),
                  ),
                ),
                if (e != null) ...[
                  ExerciseThumb(e, size: 46),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e == null ? item.exerciseId : exerciseNamePt(e.name),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (e != null)
                        Text(
                          e.primary.map(muscleLabel).join(', '),
                          style: TextStyle(fontSize: 12, color: p.muted),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remover',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: onRemove,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isCardio)
                  _Stepper('Séries', item.sets, (v) {
                    item.sets = v;
                    onChanged();
                  }),
                _Stepper(isCardio ? 'Minutos' : 'Reps', item.reps, (v) {
                  item.reps = v;
                  onChanged();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _Stepper(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: context.pal.muted)),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
        ),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w800)),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
          onPressed: () => onChanged(value + 1),
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}
