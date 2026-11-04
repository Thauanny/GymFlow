import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../state/catalog_cubit.dart';
import '../../../state/planner_cubit.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_title.dart';
import 'day_draft_card.dart';
import 'volume_card.dart';

/// Prévia da semana gerada: um cartão por dia + volume semanal por músculo.
class WeekPreview extends StatelessWidget {
  const WeekPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PlannerCubit>().state;
    if (s.drafts.isEmpty && !s.busy) return const SizedBox.shrink();
    final days = s.drafts.keys.toList()..sort();
    final byId = context.read<CatalogCubit>().byId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          'Sua semana',
          step: 4,
          hint: 'Troque, adicione ou remova exercícios e gere um dia de novo.',
        ),
        if (s.busy) _Loading(s.status, s.progress),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: s.busy ? .35 : 1,
          child: IgnorePointer(
            ignoring: s.busy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final d in days) DayDraftCard(day: d, draft: s.drafts[d]!),
                if (days.isNotEmpty)
                  VolumeCard(
                    workouts: [for (final d in days) s.drafts[d]!.workout],
                    byId: byId,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  final String status;
  final double progress;
  const _Loading(this.status, this.progress);

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        color: p.volt,
        borderColor: Colors.transparent,
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: p.onVolt,
                value: progress == 0 ? null : progress,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                status.isEmpty ? 'Montando seu plano...' : status,
                style: TextStyle(fontWeight: FontWeight.w700, color: p.onVolt),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
