import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../state/equipment_cubit.dart';
import '../../widgets/page_body.dart';
import '../../widgets/toast.dart';
import '../planner/planner_page.dart';

/// Barra fixa: salvar a seleção ou seguir para montar o treino.
class EquipmentSaveBar extends StatelessWidget {
  final VoidCallback onWorkoutSaved;
  const EquipmentSaveBar({required this.onWorkoutSaved, super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = context.watch<EquipmentCubit>().state;
    final color = s.dirty ? p.warn : p.highlight;
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
                Row(
                  children: [
                    Icon(
                      s.dirty
                          ? Icons.pending_outlined
                          : Icons.check_circle_outline_rounded,
                      size: 18,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.dirty
                            ? '${s.equipment.length} aparelho(s) · ${s.draftAvailable.length} exercícios · alterações não salvas'
                            : '${s.available.length} exercícios disponíveis · equipamentos salvos',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                s.dirty ? _saveButton(context) : _nextButtons(context, s),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _saveButton(BuildContext context) => FilledButton.icon(
    onPressed: () {
      context.read<EquipmentCubit>().save();
      showToast(context, 'Equipamentos salvos.');
    },
    icon: const Icon(Icons.save_outlined),
    label: const Text('Salvar equipamentos'),
  );

  Widget _nextButtons(BuildContext context, EquipmentState s) {
    final disabled = s.available.isEmpty;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: disabled ? null : () => openManualPlanner(context),
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Montar manual'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: disabled ? null : () => openPlanner(context),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Gerar plano'),
          ),
        ),
      ],
    );
  }
}
