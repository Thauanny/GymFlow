import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../state/progress_cubit.dart';
import '../../widgets/app_card.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/page_body.dart';
import '../../widgets/section_title.dart';
import '../home/recent_logs.dart';
import 'consistency_calendar.dart';
import 'weight_chart.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  Future<void> _addWeight(BuildContext context) async {
    final kg = await askNumber(
      context,
      title: 'Registrar peso',
      label: 'Peso (kg)',
    );
    if (kg != null && kg > 0 && context.mounted) {
      context.read<ProgressCubit>().addWeight(kg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressCubit, ProgressState>(
      builder: (context, s) {
        final recent = s.weights.length > 12
            ? s.weights.sublist(s.weights.length - 12)
            : s.weights;
        return PageBody(
          title: 'Progresso',
          subtitle: 'Frequência, peso e histórico.',
          children: [
            AppCard(child: ConsistencyCalendar(s)),
            const SectionTitle('Peso corporal'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () => _addWeight(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Registrar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  recent.isEmpty
                      ? const Text('Sem registros ainda.')
                      : WeightChart(recent),
                ],
              ),
            ),
            const SectionTitle('Histórico de treinos'),
            RecentLogs(limit: s.logs.length),
          ],
        );
      },
    );
  }
}
