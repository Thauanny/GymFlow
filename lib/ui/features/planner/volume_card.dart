import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../domain/training/weekly_volume.dart';
import '../../../models/exercise.dart';
import '../../../models/labels.dart';
import '../../../models/workout.dart';
import '../../widgets/app_card.dart';

/// Séries por músculo na semana (referência: 8–20 séries).
class VolumeCard extends StatelessWidget {
  final List<Workout> workouts;
  final Exercise? Function(String id) byId;
  const VolumeCard({required this.workouts, required this.byId, super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final volume = weeklyVolume(workouts, byId);
    final rows = [
      for (final m in muscleNames.keys)
        if (volume[m] != null) (m, volume[m]!),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    const maxSets = 24.0;
    Color colorOf(VolumeLevel l) => switch (l) {
      VolumeLevel.low => p.warn,
      VolumeLevel.ok => p.highlight,
      VolumeLevel.high => p.danger,
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Volume semanal por músculo',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          Text(
            'Séries por semana. Verde = faixa boa (8–20).',
            style: TextStyle(fontSize: 12, color: p.muted),
          ),
          const SizedBox(height: 12),
          for (final (m, sets) in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      muscleLabel(m),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (sets / maxSets).clamp(0, 1),
                        minHeight: 8,
                        color: colorOf(volumeLevel(sets)),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      sets.toStringAsFixed(
                        sets == sets.roundToDouble() ? 0 : 1,
                      ),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
