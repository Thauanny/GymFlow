import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/equipment/equipment_catalog.dart';
import '../../../state/equipment_cubit.dart';

const _homeKinds = {
  'body only',
  'bands',
  'dumbbell',
  'kettlebells',
  'exercise ball',
};

/// Atalhos de seleção: academia completa, treino em casa, só peso corporal.
class PresetsBar extends StatelessWidget {
  const PresetsBar({super.key});

  Set<String> _byKinds(Set<String> kinds) => {
    for (final i in equipItems)
      if (kinds.contains(i.dbEquip)) i.id,
  };

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EquipmentCubit>();
    final presets = <(String, IconData, Set<String>)>[
      (
        'Academia completa',
        Icons.apartment_rounded,
        equipItems.map((e) => e.id).toSet(),
      ),
      ('Treino em casa', Icons.home_rounded, _byKinds(_homeKinds)),
      (
        'Só peso corporal',
        Icons.accessibility_new_rounded,
        _byKinds({'body only'}),
      ),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Atalho rápido:',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: context.pal.muted,
          ),
        ),
        for (final (label, icon, ids) in presets)
          ActionChip(
            avatar: Icon(icon, size: 16),
            label: Text(label),
            onPressed: () => cubit.setAll(ids),
          ),
        ActionChip(
          avatar: const Icon(Icons.clear_rounded, size: 16),
          label: const Text('Limpar'),
          onPressed: () => cubit.setAll({}),
        ),
      ],
    );
  }
}
