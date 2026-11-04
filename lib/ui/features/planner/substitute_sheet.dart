import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/translation/pt_names.dart';
import '../../../domain/training/substitutes.dart';
import '../../../models/exercise.dart';
import '../../../models/labels.dart';
import '../../../state/planner_cubit.dart';
import '../../widgets/exercise_thumb.dart';

/// Trocas para um exercício: primeiro o **mesmo movimento** (terra por terra,
/// agachamento por agachamento...), em todo equipamento que você tem, agrupado
/// por equipamento; depois o mesmo músculo com outro movimento. Sem corte.
Future<void> showSubstitutes(
  BuildContext context, {
  required int day,
  required int index,
  required Exercise current,
  bool stretch = false,
}) {
  final planner = context.read<PlannerCubit>();
  final options = stretch
      ? SubstituteOptions(const [], planner.stretchSubstitutesFor(current))
      : planner.substituteOptionsFor(current);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _Sheet(
      current: current,
      options: options,
      flat: stretch,
      onPick: (e) {
        stretch
            ? planner.swapStretch(day, index, e)
            : planner.swapExercise(day, index, e);
        Navigator.pop(ctx);
      },
    ),
  );
}

class _Sheet extends StatelessWidget {
  final Exercise current;
  final SubstituteOptions options;
  final bool flat;
  final ValueChanged<Exercise> onPick;
  const _Sheet({
    required this.current,
    required this.options,
    required this.flat,
    required this.onPick,
  });

  List<Widget> _group(BuildContext context, List<Exercise> list) {
    final p = context.pal;
    final out = <Widget>[];
    String? last;
    for (final e in list) {
      if (e.equipKey != last) {
        last = e.equipKey;
        out.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 2),
            child: Text(
              equipLabel(e.equipKey).toUpperCase(),
              style: AppText.eyebrow(p.muted),
            ),
          ),
        );
      }
      out.add(
        ListTile(
          leading: ExerciseThumb(e, size: 48),
          title: Text(
            exerciseNamePt(e.name),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(e.primary.map(muscleLabel).join(', ')),
          onTap: () => onPick(e),
        ),
      );
    }
    return out;
  }

  Widget _title(BuildContext context, String text, int n) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
    child: Text(
      '$text · $n',
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
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
            'Só equipamentos que você marcou na Academia.',
            style: TextStyle(fontSize: 13, color: p.muted),
          ),
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
                  if (options.sameMovement.isNotEmpty) ...[
                    _title(
                      context,
                      'Mesmo movimento',
                      options.sameMovement.length,
                    ),
                    ..._group(context, options.sameMovement),
                  ],
                  if (options.sameMuscle.isNotEmpty) ...[
                    _title(
                      context,
                      flat ? 'Mesmo músculo' : 'Mesmo músculo, outro movimento',
                      options.sameMuscle.length,
                    ),
                    ..._group(context, options.sameMuscle),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
