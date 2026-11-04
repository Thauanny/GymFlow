import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format.dart';
import '../../../state/progress_cubit.dart';
import '../../widgets/app_card.dart';

class RecentLogs extends StatelessWidget {
  final int limit;
  const RecentLogs({this.limit = 5, super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return BlocBuilder<ProgressCubit, ProgressState>(
      builder: (context, s) {
        if (s.logs.isEmpty) {
          return Text(
            'Nenhum treino registrado ainda.',
            style: TextStyle(color: p.muted),
          );
        }
        final logs = s.logs.take(limit).toList();
        return AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              for (final (i, l) in logs.indexed) ...[
                if (i > 0) const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: p.volt,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: p.onVolt,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.workoutName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${formatDate(l.date)} · ${l.exercises} exercícios',
                              style: TextStyle(fontSize: 12.5, color: p.muted),
                            ),
                          ],
                        ),
                      ),
                      Text('${l.minutes}', style: AppText.display(28)),
                      Text(' min', style: TextStyle(color: p.muted)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
