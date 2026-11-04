import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ai/goal_text.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../domain/training/training_profile.dart';
import '../../../models/labels.dart';
import '../../../state/planner_cubit.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_title.dart';

const _goalIcons = {
  TrainingGoal.hypertrophy: Icons.fitness_center_rounded,
  TrainingGoal.strength: Icons.bolt_rounded,
  TrainingGoal.fatLoss: Icons.local_fire_department_rounded,
  TrainingGoal.endurance: Icons.timer_rounded,
};

/// Objetivo do treino + texto livre (ex.: "fortalecer glúteos").
class GoalSection extends StatefulWidget {
  const GoalSection({super.key});

  @override
  State<GoalSection> createState() => _GoalSectionState();
}

class _GoalSectionState extends State<GoalSection> {
  late final _text = TextEditingController(
    text: context.read<PlannerCubit>().state.profile.goalText,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerCubit>();
    final profile = planner.state.profile;
    final p = context.pal;
    final detected = musclesFromText(profile.goalText);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Seu objetivo', step: 1),
        LayoutBuilder(
          builder: (_, c) {
            final cols = c.maxWidth >= 640 ? 4 : 2;
            final w = (c.maxWidth - (cols - 1) * 10) / cols;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final g in TrainingGoal.values)
                  SizedBox(
                    width: w,
                    child: AppCard(
                      onTap: () =>
                          planner.updateProfile(profile.copyWith(goal: g)),
                      borderColor: profile.goal == g ? p.volt : null,
                      color: profile.goal == g ? p.volt : null,
                      radius: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _goalIcons[g],
                            color: profile.goal == g ? p.onVolt : p.muted,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            g.label.toUpperCase(),
                            style: AppText.display(
                              26,
                              color: profile.goal == g ? p.onVolt : p.text,
                            ),
                          ),
                          Text(
                            g.description,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: profile.goal == g
                                  ? p.onVolt.withValues(alpha: .75)
                                  : p.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _text,
          onChanged: (v) =>
              planner.updateProfile(profile.copyWith(goalText: v)),
          decoration: const InputDecoration(
            hintText:
                'Opcional: "fortalecer glúteos e costas", "definir abdômen"...',
            prefixIcon: Icon(Icons.edit_note_rounded),
          ),
        ),
        if (detected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Vou dar destaque a: ${detected.map(muscleLabel).join(', ')}',
              style: TextStyle(
                fontSize: 12.5,
                color: p.highlight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (profile.goalText.trim().isNotEmpty)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: planner.state.useSemantic,
            onChanged: planner.setSemantic,
            title: const Text('Usar IA semântica (opcional)'),
            subtitle: const Text(
              'Baixa um modelo (~50 MB) na primeira vez para entender textos livres.',
            ),
          ),
      ],
    );
  }
}
