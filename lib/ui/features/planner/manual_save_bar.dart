import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../models/labels.dart';
import '../../../state/planner_cubit.dart';
import '../../../state/planner_state.dart';
import '../../widgets/page_body.dart';

/// Barra fixa da montagem manual: salvar a semana.
class ManualSaveBar extends StatelessWidget {
  final VoidCallback onSave;
  const ManualSaveBar({required this.onSave, super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return BlocBuilder<PlannerCubit, PlannerState>(
      builder: (context, s) {
        final planner = context.read<PlannerCubit>();
        final empty = planner.emptyDays;
        final ready = planner.hasContent && empty.isEmpty;
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
                    if (empty.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Adicione exercícios em: '
                          '${empty.map((d) => weekdayFull[d - 1]).join(', ')}. '
                          'Ou tire o dia da lista acima.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: p.warn),
                        ),
                      ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: p.volt,
                        foregroundColor: p.onVolt,
                      ),
                      onPressed: ready ? onSave : null,
                      icon: const Icon(Icons.bookmark_add_rounded),
                      label: const Text('Salvar plano'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
