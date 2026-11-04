import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format.dart';
import '../../../models/labels.dart';
import '../../../state/progress_cubit.dart';

/// Os últimos 7 dias: treinou = preenchido; hoje = contorno.
class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final today = dateOnly(DateTime.now());
    final days = [
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    return BlocBuilder<ProgressCubit, ProgressState>(
      builder: (context, s) => Row(
        children: [
          for (final d in days)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: s.trainedOn(d) ? p.volt : p.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: d == today ? p.text : p.border,
                    width: d == today ? 1.8 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      weekdayNames[d.weekday - 1].toUpperCase(),
                      style: AppText.eyebrow(
                        s.trainedOn(d) ? p.onVolt : p.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${d.day}',
                      style: AppText.display(
                        24,
                        color: s.trainedOn(d) ? p.onVolt : p.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
