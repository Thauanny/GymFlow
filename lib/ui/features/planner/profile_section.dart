import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/labels.dart';
import '../../../state/planner_cubit.dart';
import '../../widgets/section_title.dart';

const _durations = [30, 45, 60, 75, 90];

/// Nível e tempo disponível por sessão.
class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerCubit>();
    final profile = planner.state.profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Nível e tempo', step: 2),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            for (final l in levelNames.entries)
              ButtonSegment(value: l.key, label: Text(l.value)),
          ],
          selected: {profile.level},
          onSelectionChanged: (v) =>
              planner.updateProfile(profile.copyWith(level: v.first)),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          children: [
            for (final m in _durations)
              ChoiceChip(
                label: Text('$m min'),
                selected: profile.minutes == m,
                onSelected: (_) =>
                    planner.updateProfile(profile.copyWith(minutes: m)),
              ),
          ],
        ),
      ],
    );
  }
}
