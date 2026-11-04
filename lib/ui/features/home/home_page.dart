import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../state/progress_cubit.dart';
import '../../widgets/page_body.dart';
import '../../widgets/section_title.dart';
import '../settings/install_guide.dart';
import 'recent_logs.dart';
import 'stats_band.dart';
import 'today_card.dart';
import 'week_strip.dart';

String _greeting() {
  final h = DateTime.now().hour;
  return h < 12 ? 'Bom dia' : (h < 18 ? 'Boa tarde' : 'Boa noite');
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageBody(
      title: _greeting(),
      subtitle: 'Pronto para o treino de hoje?',
      children: [
        const InstallBanner(),
        const TodayCard(),
        const SizedBox(height: 16),
        BlocBuilder<ProgressCubit, ProgressState>(
          builder: (context, s) => StatsBand(s),
        ),
        const SectionTitle('Últimos 7 dias'),
        const WeekStrip(),
        const SectionTitle('Últimos treinos'),
        const RecentLogs(),
      ],
    );
  }
}
