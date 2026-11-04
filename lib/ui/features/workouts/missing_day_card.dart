import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../models/labels.dart';
import '../../../state/equipment_cubit.dart';
import '../../widgets/app_card.dart';
import '../planner/planner_page.dart';

/// Dia escolhido que ainda não tem treino.
class MissingDayCard extends StatelessWidget {
  final int weekday;
  const MissingDayCard(this.weekday, {super.key});

  @override
  Widget build(BuildContext context) {
    final ready = context.select<EquipmentCubit, bool>(
      (c) => c.state.available.isNotEmpty,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Treino de ${weekdayFull[weekday - 1]} ainda não criado.',
              style: TextStyle(color: context.pal.muted, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: ready ? () => openPlanner(context) : null,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Gerar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: ready
                        ? () => openManualPlanner(context, weekday: weekday)
                        : null,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Criar manual'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
