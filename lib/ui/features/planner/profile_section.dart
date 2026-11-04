import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../models/labels.dart';
import '../../widgets/app_card.dart';
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
    final p = context.pal;
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
        const SizedBox(height: 14),
        AppCard(
          padding: EdgeInsets.zero,
          child: SwitchListTile(
            contentPadding: const EdgeInsets.fromLTRB(18, 6, 12, 6),
            secondary: Icon(Icons.self_improvement_rounded, color: p.muted),
            value: profile.stretching,
            onChanged: (v) =>
                planner.updateProfile(profile.copyWith(stretching: v)),
            title: const Text(
              'Incluir alongamentos',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              'Uma ficha de alongamentos para os músculos treinados no dia.',
              style: TextStyle(fontSize: 12.5, color: p.muted),
            ),
          ),
        ),
      ],
    );
  }
}
