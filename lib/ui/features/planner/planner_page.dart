import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../state/nav_cubit.dart';
import '../../../state/planner_cubit.dart';
import '../../../state/planner_state.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/page_body.dart';
import '../../widgets/toast.dart';
import 'avoid_section.dart';
import 'days_section.dart';
import 'generate_bar.dart';
import 'goal_section.dart';
import 'profile_section.dart';
import 'week_preview.dart';

Future<void> openPlanner(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute(builder: (_) => const PlannerPage()));

/// Monta o plano semanal: objetivo, dias, foco e geração.
class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  final _previewKey = GlobalKey();

  /// Leva a tela até a semana gerada e avisa.
  void _showResult() {
    showToast(context, 'Plano gerado! Confira a semana abaixo.');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _previewKey.currentContext;
      if (c != null) {
        Scrollable.ensureVisible(
          c,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _save(BuildContext context) async {
    final planner = context.read<PlannerCubit>();
    var replace = false;
    if (planner.hasConflicts()) {
      replace = await confirmDialog(
        context,
        title: 'Substituir treinos?',
        message: 'Já existem treinos nos dias gerados. Substituir pelos novos?',
        confirm: 'Substituir',
      );
      if (!context.mounted) return;
    }
    final n = planner.commit(replaceDays: replace);
    context.read<NavCubit>().go(AppTab.workouts);
    showToast(context, '$n treino(s) salvo(s) na semana');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: BlocBuilder<PlannerCubit, PlannerState>(
        builder: (context, s) => PageBody(
          title: 'Plano semanal',
          subtitle: 'Objetivo, dias e função de cada treino.',
          bottom: GenerateBar(
            onSave: () => _save(context),
            onGenerated: _showResult,
          ),
          children: [
            const GoalSection(),
            const ProfileSection(),
            const AvoidSection(),
            const DaysSection(),
            KeyedSubtree(key: _previewKey, child: const WeekPreview()),
          ],
        ),
      ),
    );
  }
}
