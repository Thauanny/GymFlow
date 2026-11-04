import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/equipment/equipment_catalog.dart';
import '../../../domain/training/dual_cable.dart';
import '../../../state/equipment_cubit.dart';
import '../../../state/planner_cubit.dart';
import '../../widgets/app_card.dart';

/// Aparelhos que o usuário não quer usar neste plano (ex.: polia dupla em
/// academia pequena). Continuam na lista da academia, só não entram nos treinos.
class AvoidSection extends StatelessWidget {
  const AvoidSection({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final owned = context.watch<EquipmentCubit>().state.saved;
    final avoided = context.watch<PlannerCubit>().state.avoidedItems;
    final items = [
      for (final i in equipItems)
        if (owned.contains(i.id)) i,
    ];
    final count = avoided
        .where((id) => id != dualCableKey && owned.contains(id))
        .length;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: const EdgeInsets.fromLTRB(18, 6, 12, 6),
              secondary: Icon(
                Icons.swap_horizontal_circle_outlined,
                color: p.muted,
              ),
              value: avoided.contains(dualCableKey),
              onChanged: (_) =>
                  context.read<PlannerCubit>().toggleAvoid(dualCableKey),
              title: const Text(
                'Evitar polia dupla (cabos dos dois lados)',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                'Academia pequena? Tira crossover, voador e supino na polia, '
                'cruz de ferro e outros que ocupam a estação inteira.',
                style: TextStyle(fontSize: 12.5, color: p.muted),
              ),
            ),
            if (items.isNotEmpty) ...[
              const Divider(),
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 18),
                  childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  leading: Icon(Icons.block_rounded, color: p.muted),
                  title: const Text(
                    'Evitar outros aparelhos',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    count == 0
                        ? 'Marque os que não quer usar neste plano.'
                        : '$count aparelho(s) fora dos treinos gerados',
                    style: TextStyle(fontSize: 12.5, color: p.muted),
                  ),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final sec in sections.entries)
                      _Group(
                        title: sec.value,
                        items: [
                          for (final i in items)
                            if (i.section == sec.key) i,
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<EquipItem> items;
  const _Group({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final avoided = context.select<PlannerCubit, Set<String>>(
      (c) => c.state.avoidedItems,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: context.pal.muted,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final i in items)
              FilterChip(
                avatar: avoided.contains(i.id)
                    ? const Icon(Icons.block_rounded, size: 16)
                    : null,
                label: Text(i.label),
                selected: avoided.contains(i.id),
                onSelected: (_) =>
                    context.read<PlannerCubit>().toggleAvoid(i.id),
              ),
          ],
        ),
      ],
    );
  }
}
