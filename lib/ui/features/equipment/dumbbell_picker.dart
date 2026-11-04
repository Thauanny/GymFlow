import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/equipment/equipment_catalog.dart';
import '../../../state/equipment_cubit.dart';
import '../../widgets/app_card.dart';

/// Pesos de halteres disponíveis (sempre visível, recolhido).
class DumbbellPicker extends StatelessWidget {
  const DumbbellPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<EquipmentCubit>().state;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 18),
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            leading: Icon(
              Icons.fitness_center_rounded,
              color: context.pal.muted,
            ),
            title: const Text(
              'Halteres disponíveis (kg)',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              s.dumbbells.isEmpty
                  ? 'Opcional: ajuda a sugerir a carga de cada treino.'
                  : '${s.dumbbells.length} peso(s) marcado(s)',
              style: TextStyle(fontSize: 12.5, color: context.pal.muted),
            ),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
      ),
    );
  }
}
