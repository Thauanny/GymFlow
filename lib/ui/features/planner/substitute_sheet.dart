import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/equipment/equipment_matcher.dart';
import '../../../data/translation/pt_names.dart';
import '../../../models/exercise.dart';
import '../../../models/labels.dart';
import '../../../state/planner_cubit.dart';
import '../../widgets/exercise_thumb.dart';

/// Sugere trocas do mesmo músculo e tipo de movimento para um exercício.
Future<void> showSubstitutes(
  BuildContext context, {
  required int day,
  required int index,
  required Exercise current,
  bool stretch = false,
}) {
  final planner = context.read<PlannerCubit>();
  final options = stretch
      ? planner.stretchSubstitutesFor(current)
      : planner.substitutesFor(current);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trocar ${exerciseNamePt(current.name)}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          Text(
            'Mesmo músculo, com os equipamentos que você tem.',
            style: TextStyle(fontSize: 13, color: ctx.pal.muted),
          ),
          const SizedBox(height: 8),
          if (options.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Sem outras opções disponíveis para este exercício.'),
            )
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final e in options)
                    ListTile(
                      leading: ExerciseThumb(e, size: 48),
                      title: Text(
                        exerciseNamePt(e.name),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        itemForExercise(e)?.label ?? equipLabel(e.equipKey),
                      ),
                      onTap: () {
                        stretch
                            ? planner.swapStretch(day, index, e)
                            : planner.swapExercise(day, index, e);
                        Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
