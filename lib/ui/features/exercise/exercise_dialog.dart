import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/alternatives_service.dart';
import '../../../data/equipment/equipment_matcher.dart';
import '../../../data/gif_catalog.dart';
import '../../../data/translation/pt_names.dart';
import '../../../models/exercise.dart';
import '../../../models/labels.dart';
import '../../../state/equipment_cubit.dart';
import '../../widgets/pill.dart';
import 'alternatives_strip.dart';
import 'exercise_media.dart';

/// Detalhes do exercício: imagem, resumo em português e alternativas.
void showExercise(BuildContext context, Exercise e) {
  final gif = context.read<GifCatalog>().gifFor(e);
  final alternatives = context.read<AlternativesService>();
  final owned = context.read<EquipmentCubit>().state.saved;
  final alts = alternatives.alternativesFor(e, owned);
  showDialog<void>(
    context: context,
    builder: (dialogCtx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExerciseMedia(e, gif),
                  const SizedBox(height: 16),
                  Text(
                    exerciseNamePt(e.name).toUpperCase(),
                    style: AppText.display(32),
                  ),
                  const SizedBox(height: 12),
                  _Facts(e),
                  if (alts.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    AlternativesStrip(
                      alts: alts,
                      onOpen: (a) =>
                          showExercise(context, alternatives.exerciseForAlt(a)),
                    ),
                  ],
                ],
              ),
            ),
            // Fixo no canto: não rola junto e tem área de toque grande.
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                tooltip: 'Fechar',
                style: IconButton.styleFrom(
                  backgroundColor: dialogCtx.pal.accent,
                  foregroundColor: dialogCtx.pal.onAccent,
                  minimumSize: const Size(44, 44),
                ),
                onPressed: () => Navigator.of(dialogCtx).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Resumo curto e em português (músculos, aparelho, nível e tipo).
class _Facts extends StatelessWidget {
  final Exercise exercise;
  const _Facts(this.exercise);

  static const _movement = {
    'push': 'Empurrar',
    'pull': 'Puxar',
    'static': 'Isométrico',
  };

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final e = exercise;
    final move = _movement[e.force];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Row('Trabalha', [
          for (final m in e.primary) Pill(muscleLabel(m), color: p.highlight),
        ]),
        if (e.secondary.isNotEmpty)
          _Row('Ajuda', [
            for (final m in e.secondary)
              Pill(muscleLabel(m), color: p.tints[4]),
          ]),
        _Row('Detalhes', [
          Pill(equipmentLabelOf(e), color: p.tints[2]),
          Pill(levelNames[e.level] ?? e.level, color: p.warn),
          Pill(
            e.isCardio ? 'Cardio' : (e.isCompound ? 'Composto' : 'Isolado'),
            color: p.accent,
          ),
          if (move != null) Pill(move, color: p.tints[3]),
        ]),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final List<Widget> pills;
  const _Row(this.label, this.pills);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppText.eyebrow(context.pal.muted)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: pills),
        ],
      ),
    );
  }
}
