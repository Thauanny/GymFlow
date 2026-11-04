import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/alternatives_service.dart';
import '../../../data/alt.dart';
import '../../../data/equipment/equipment_catalog.dart';
import '../../../data/equipment/equipment_matcher.dart';
import '../../../models/labels.dart';
import '../../../state/equipment_cubit.dart';
import '../../widgets/gif_view.dart';
import '../exercise/exercise_dialog.dart';

/// Variação de exercício em outro equipamento, com botão para adicioná-lo.
class AltCard extends StatelessWidget {
  final Alt alt;
  final EquipItem? original;
  final ValueChanged<EquipItem>? onPicked;
  final bool inDialog;
  final double width;

  const AltCard(
    this.alt, {
    this.original,
    this.onPicked,
    this.inDialog = true,
    this.width = 170,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final target = itemForAlt(alt.name, alt.equip, alt.target);
    return BlocBuilder<EquipmentCubit, EquipmentState>(
      builder: (context, s) {
        final chosen = target != null && s.equipment.contains(target.id);
        final highlight = chosen || alt.have;
        final service = context.read<AlternativesService>();
        return Container(
          width: width,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlight ? p.highlight : p.border,
              width: highlight ? 2 : 1,
            ),
          ),
          // Alturas fixas: todos os cartões ficam iguais e os botões alinhados.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () => showExercise(context, service.exerciseForAlt(alt)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GifView(alt.gif, height: 120),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                      child: SizedBox(
                        height: _nameHeight,
                        child: Text(
                          service.altNamePt(alt),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                      child: SizedBox(
                        height: _labelHeight,
                        child: Text(
                          target?.label ?? equipLabel(alt.equip),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: p.muted,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: target == null
                    ? const SizedBox(height: _buttonHeight)
                    : SizedBox(
                        height: _buttonHeight,
                        child: _action(context, s, target, chosen),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Botão compacto: o texto cabe mesmo em cartões estreitos.
  static final _buttonStyle = ButtonStyle(
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6)),
    minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
  );

  static const _nameHeight = 32.0;
  static const _labelHeight = 30.0;
  static const _buttonHeight = 44.0;

  Widget _action(
    BuildContext context,
    EquipmentState s,
    EquipItem target,
    bool chosen,
  ) {
    if (chosen) {
      return FilledButton(
        onPressed: null,
        style: _buttonStyle,
        child: const Text('Selecionado', style: TextStyle(fontSize: 13)),
      );
    }
    final replace =
        original != null &&
        s.equipment.contains(original!.id) &&
        target.id != original!.id;
    return OutlinedButton(
      style: _buttonStyle,
      onPressed: () {
        context.read<EquipmentCubit>().swap(
          replace ? original!.id : null,
          target.id,
        );
        if (inDialog) Navigator.of(context).pop();
        onPicked?.call(target);
      },
      child: Text(
        replace ? 'Usar no lugar' : 'Adicionar',
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}

/// Largura dos cards de alternativa: 2 colunas no celular, mais em telas largas.
double altCardWidth(double maxWidth) {
  final cols = maxWidth >= 700 ? 4 : (maxWidth >= 480 ? 3 : 2);
  return (maxWidth - (cols - 1) * 10) / cols;
}
