import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../state/equipment_cubit.dart';
import '../../../state/planner_cubit.dart';
import '../../../state/planner_state.dart';
import '../../../state/workouts_cubit.dart';
import '../../widgets/page_body.dart';

/// Barra fixa: gerar a semana e salvar o plano.
class GenerateBar extends StatelessWidget {
  final VoidCallback onSave, onGenerated;
  const GenerateBar({
    required this.onSave,
    required this.onGenerated,
    super.key,
  });

  Future<void> _generate(BuildContext context) async {
    await context.read<PlannerCubit>().generateWeek();
    if (context.mounted) onGenerated();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = context.watch<PlannerCubit>().state;
    final days = context.watch<WorkoutsCubit>().state.sortedDays;
    final hasEquipment = context
        .watch<EquipmentCubit>()
        .state
        .available
        .isNotEmpty;
    final canGenerate = !s.busy && hasEquipment && days.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: p.card,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: contentMaxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (s.busy) _Progress(s),
                if (!hasEquipment)
                  Text(
                    'Escolha seus equipamentos para gerar o plano.',
                    style: TextStyle(color: p.warn),
                  )
                else if (days.isEmpty)
                  Text(
                    'Selecione ao menos um dia da semana.',
                    style: TextStyle(color: p.muted),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: canGenerate
                            ? () => _generate(context)
                            : null,
                        icon: s.busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              )
                            : const Icon(Icons.auto_awesome_rounded),
                        label: Text(
                          s.busy
                              ? 'Gerando...'
                              : (s.drafts.isEmpty
                                    ? 'Gerar semana'
                                    : 'Gerar de novo'),
                        ),
                      ),
                    ),
                    if (s.drafts.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: p.volt,
                            foregroundColor: p.onVolt,
                          ),
                          onPressed: s.busy ? null : onSave,
                          icon: const Icon(Icons.bookmark_add_rounded),
                          label: const Text('Salvar plano'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  final PlannerState s;
  const _Progress(this.s);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: s.progress == 0 ? null : s.progress),
          const SizedBox(height: 4),
          Text(s.status, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
