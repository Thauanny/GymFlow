import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/alternatives_service.dart';
import '../../../data/equipment/equipment_catalog.dart';
import '../../../models/exercise.dart';
import '../../../state/equipment_cubit.dart';
import 'alt_card.dart';

/// Alternativas (outros equipamentos) para o exercício principal de um aparelho.
void showAlternatives(
  BuildContext context,
  EquipItem item,
  Exercise? exercise, {
  ValueChanged<EquipItem>? onPicked,
}) {
  final owned = context.read<EquipmentCubit>().state.saved;
  final alts = exercise == null
      ? []
      : context.read<AlternativesService>().alternativesFor(
          exercise,
          owned,
          max: 12,
        );
  showDialog<void>(
    context: context,
    builder: (dialogCtx) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Sem ${item.label}? Faça de outra forma',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.pop(dialogCtx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Variações do mesmo movimento com outros equipamentos. '
                'As do seu equipamento salvo aparecem primeiro.',
                style: TextStyle(fontSize: 13, color: dialogCtx.pal.muted),
              ),
              const SizedBox(height: 14),
              if (alts.isEmpty)
                const Text('Ainda não há variações para este aparelho.')
              else
                LayoutBuilder(
                  builder: (_, c) => Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final a in alts)
                        AltCard(
                          a,
                          original: item,
                          onPicked: onPicked,
                          width: altCardWidth(c.maxWidth),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
