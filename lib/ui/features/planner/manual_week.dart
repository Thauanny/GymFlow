import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../state/catalog_cubit.dart';
import '../../../state/planner_cubit.dart';
import '../../widgets/section_title.dart';
import 'day_draft_card.dart';
import 'volume_card.dart';

/// Montagem manual: um cartão por dia escolhido (os mesmos do plano gerado),
/// começando vazios para você adicionar exercícios e alongamentos.
class ManualWeek extends StatelessWidget {
  const ManualWeek({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PlannerCubit>().state;
    final days = s.drafts.keys.toList()..sort();
    final byId = context.read<CatalogCubit>().byId;
    if (days.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Text(
          'Escolha os dias da semana acima para começar.',
          style: TextStyle(color: context.pal.muted),
        ),
      );
    }
    final any = [
      for (final d in days)
        if (s.drafts[d]!.workout.items.isNotEmpty) s.drafts[d]!.workout,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          'Seus treinos',
          step: 2,
          hint:
              'Cada dia é um treino separado. Adicione o que quiser em cada um.',
        ),
        for (final d in days)
          DayDraftCard(day: d, draft: s.drafts[d]!, manual: true),
        if (any.isNotEmpty) VolumeCard(workouts: any, byId: byId),
      ],
    );
  }
}
