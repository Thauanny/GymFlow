import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../models/labels.dart';

/// Seleção de dias da semana (1 = segunda ... 7 = domingo).
class WeekdaySelector extends StatelessWidget {
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;
  final Set<int> marked; // dias com marca (ex.: treino gerado)

  const WeekdaySelector({
    required this.selected,
    required this.onChanged,
    this.marked = const {},
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      children: [
        for (var d = 1; d <= 7; d++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  final next = {...selected};
                  next.contains(d) ? next.remove(d) : next.add(d);
                  onChanged(next);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 54,
                  decoration: BoxDecoration(
                    color: selected.contains(d) ? p.accent : p.cardAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        weekdayNames[d - 1],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: selected.contains(d) ? p.onAccent : p.muted,
                        ),
                      ),
                      if (marked.contains(d))
                        Icon(Icons.check_rounded, size: 14, color: p.highlight),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
