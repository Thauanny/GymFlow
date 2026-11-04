import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/labels.dart';
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
import 'manual_save_bar.dart';
import 'manual_week.dart';
import 'week_preview.dart';

Future<void> openPlanner(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute(builder: (_) => const PlannerPage()));

/// Montagem manual: a mesma tela do plano gerado, mas com os dias vazios.
/// Com [weekday], esse dia já vem selecionado.
Future<void> openManualPlanner(BuildContext context, {int? weekday}) {
  final planner = context.read<PlannerCubit>();
  if (weekday != null && !planner.days.contains(weekday)) {
    planner.setDays({...planner.days, weekday});
  }
  return Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const PlannerPage(manual: true)));
}

/// Monta o plano semanal: objetivo, dias, foco e geração.
class PlannerPage extends StatefulWidget {
  final bool manual;
  const PlannerPage({this.manual = false, super.key});

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
    final empty = planner.emptyDays;
    if (!planner.hasContent || empty.isNotEmpty) {
      showToast(
        context,
        empty.isEmpty
            ? 'Adicione ao menos um exercício.'
            : 'Faltam exercícios em: '
                  '${empty.map((d) => weekdayFull[d - 1]).join(', ')}.',
        error: true,
      );
      return;
    }
    final n = planner.commit(replaceDays: replace);
    context.read<NavCubit>().go(AppTab.workouts);
    showToast(context, '$n treino(s) salvo(s) na semana');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final manual = widget.manual;
    return Scaffold(
      appBar: AppBar(),
      body: BlocBuilder<PlannerCubit, PlannerState>(
        builder: (context, s) {
          if (manual) {
            // Um treino vazio por dia escolhido (só emite se algo mudou).
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.read<PlannerCubit>().ensureManualDrafts();
            });
          }
          return PageBody(
            title: manual ? 'Montar manual' : 'Plano semanal',
            subtitle: manual
                ? 'Escolha os dias e adicione os exercícios de cada um.'
                : 'Objetivo, dias e função de cada treino.',
            bottom: manual
                ? ManualSaveBar(onSave: () => _save(context))
                : GenerateBar(
                    onSave: () => _save(context),
                    onGenerated: _showResult,
                  ),
            children: manual
                ? const [DaysSection(manual: true), ManualWeek()]
                : [
                    const GoalSection(),
                    const ProfileSection(),
                    const AvoidSection(),
                    const DaysSection(),
                    KeyedSubtree(key: _previewKey, child: const WeekPreview()),
                  ],
          );
        },
      ),
    );
  }
}
