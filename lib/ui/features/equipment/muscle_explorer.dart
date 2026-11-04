import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/alternatives_service.dart';
import '../../../data/equipment/equipment_catalog.dart';
import '../../../models/labels.dart';
import '../../../state/equipment_cubit.dart';
import '../../widgets/app_card.dart';
import 'alt_card.dart';

const _pageSize =
    8; // cada resultado tem um GIF: poucos por vez deixa o scroll leve

/// Escolha um músculo e veja os exercícios em todos os equipamentos.
class MuscleExplorer extends StatefulWidget {
  final String? muscle;
  final ValueChanged<String?> onMuscle;
  final ValueChanged<EquipItem> onPicked;

  const MuscleExplorer({
    required this.muscle,
    required this.onMuscle,
    required this.onPicked,
    super.key,
  });

  @override
  State<MuscleExplorer> createState() => _MuscleExplorerState();
}

class _MuscleExplorerState extends State<MuscleExplorer> {
  int _shown = _pageSize;

  @override
  Widget build(BuildContext context) {
    final muscle = widget.muscle;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrar por músculo',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final m in muscleNames.entries)
                  if (m.key != 'neck')
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(m.value),
                        selected: muscle == m.key,
                        onSelected: (on) {
                          setState(() => _shown = _pageSize);
                          widget.onMuscle(on ? m.key : null);
                        },
                      ),
                    ),
              ],
            ),
          ),
          if (muscle != null) _results(context, muscle),
        ],
      ),
    );
  }

  Widget _results(BuildContext context, String muscle) {
    final owned = context.read<EquipmentCubit>().state.saved;
    final alts = context.read<AlternativesService>().altsForMuscle(
      muscle,
      owned,
    );
    final shown = alts.take(_shown).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(
          '${alts.length} exercícios de ${muscleLabel(muscle)} em todos os equipamentos',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (_, c) => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final a in shown)
                AltCard(
                  a,
                  inDialog: false,
                  onPicked: widget.onPicked,
                  width: altCardWidth(c.maxWidth),
                ),
            ],
          ),
        ),
        if (alts.length > shown.length)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _shown += _pageSize),
              icon: const Icon(Icons.expand_more_rounded),
              label: Text('Ver mais (${alts.length - shown.length})'),
            ),
          ),
      ],
    );
  }
}
