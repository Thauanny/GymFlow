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

  /// Alongamento: as repetições são os segundos de cada posição.
  final bool stretch;

  const EditorItemRow({
    required this.index,
    required this.exercise,
    required this.item,
    required this.onRemove,
    required this.onChanged,
    this.stretch = false,
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
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (!isCardio || stretch)
                  _Stepper('Séries', item.sets, (v) {
                    item.sets = v;
                    onChanged();
                  }),
                _Stepper(
                  stretch ? 'Segundos' : (isCardio ? 'Minutos' : 'Reps'),
                  item.reps,
                  (v) {
                    item.reps = v;
                    onChanged();
                  },
                  step: stretch ? 5 : 1,
                ),
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
  final int step;
  const _Stepper(this.label, this.value, this.onChanged, {this.step = 1});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: context.pal.muted)),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
          onPressed: value > step ? () => onChanged(value - step) : null,
        ),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w800)),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
          onPressed: () => onChanged(value + step),
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}
