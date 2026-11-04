import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../state/progress_cubit.dart';

/// Números principais em blocos coloridos suaves.
class StatsBand extends StatelessWidget {
  final ProgressState state;
  const StatsBand(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final weight = state.weights.isEmpty ? '--' : '${state.weights.last.kg}';
    final stats = [
      ('Treinos', '${state.logs.length}', Icons.check_circle_rounded),
      (
        'Sequência (dias)',
        '${state.streakDays}',
        Icons.local_fire_department_rounded,
      ),
      ('Minutos', '${state.totalMinutes}', Icons.timer_rounded),
      ('Peso (kg)', weight, Icons.monitor_weight_rounded),
    ];
    return LayoutBuilder(
      builder: (_, c) {
        final cols = c.maxWidth >= 640 ? 4 : 2;
        final w = (c.maxWidth - (cols - 1) * 12) / cols;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (i, s) in stats.indexed)
              Container(
                width: w,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: p.softTints[i],
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(s.$3, size: 20, color: p.text.withValues(alpha: .7)),
                    const SizedBox(height: 14),
                    Text(s.$2, style: AppText.display(46)),
                    const SizedBox(height: 2),
                    Text(
                      s.$1,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: p.text.withValues(alpha: .65),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
