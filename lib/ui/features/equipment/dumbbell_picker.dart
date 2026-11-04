import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/equipment/equipment_catalog.dart';
import '../../../state/equipment_cubit.dart';
import '../../widgets/app_card.dart';

/// Pesos de halteres disponíveis (aparece quando há halteres selecionados).
class DumbbellPicker extends StatelessWidget {
  const DumbbellPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<EquipmentCubit>().state;
    final hasDumbbells = equipItems.any(
      (i) => i.dbEquip == 'dumbbell' && s.equipment.contains(i.id),
    );
    if (!hasDumbbells) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Halteres disponíveis (kg)',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              'Opcional: ajuda a sugerir a carga de cada treino.',
              style: TextStyle(fontSize: 12.5, color: context.pal.muted),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final kg in dumbbellWeights)
                  FilterChip(
                    label: Text('$kg'),
                    selected: s.dumbbells.contains(kg),
                    onSelected: (_) =>
                        context.read<EquipmentCubit>().toggleDumbbell(kg),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
