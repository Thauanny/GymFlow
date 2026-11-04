import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../models/labels.dart';
import '../../../state/workouts_cubit.dart';

/// Os 7 dias da semana: escolha um para ver ou montar o treino dele.
class WeekPicker extends StatelessWidget {
  final WorkoutsState state;
  final int selected;
  final ValueChanged<int> onSelect;
  const WeekPicker({
    required this.state,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final today = DateTime.now().weekday;
    return Row(
      children: [
        for (var d = 1; d <= 7; d++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onSelect(d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected == d ? p.accent : p.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected == d ? p.accent : p.border,
                    ),
                  ),
                  child: _Day(
                    d: d,
                    selected: selected == d,
                    isToday: d == today,
                    hasWorkout: state.forWeekday(d).isNotEmpty,
                    isTrainDay: state.trainDays.contains(d),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Day extends StatelessWidget {
  final int d;
  final bool selected, isToday, hasWorkout, isTrainDay;
  const _Day({
    required this.d,
    required this.selected,
    required this.isToday,
    required this.hasWorkout,
    required this.isTrainDay,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final fg = selected
        ? p.onAccent
        : (isTrainDay || hasWorkout ? p.text : p.muted);
    return Column(
      children: [
        Text(
          weekdayNames[d - 1].toUpperCase(),
          style: AppText.eyebrow(selected ? p.onAccent : p.muted),
        ),
        const SizedBox(height: 4),
        Text(isToday ? 'HOJE' : '', style: AppText.display(14, color: fg)),
        const SizedBox(height: 6),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasWorkout
                ? (selected ? p.volt : p.highlight)
                : Colors.transparent,
            border: Border.all(
              color: hasWorkout
                  ? Colors.transparent
                  : (isTrainDay ? p.warn : Colors.transparent),
              width: 2,
            ),
          ),
        ),
      ],
    );
  }
}
