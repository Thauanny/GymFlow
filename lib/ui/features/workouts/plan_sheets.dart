import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../models/labels.dart';
import '../../../state/plan_actions.dart';
import '../../widgets/app_card.dart';
import '../planner/planner_page.dart';

/// "Mudar plano": gera treinos novos para só o dia escolhido ou a semana toda.
Future<void> showChangePlanSheet(BuildContext context, {required int day}) =>
    _open(
      context,
      _PlanSheet(
        title: 'Mudar plano',
        intro:
            'Gera treinos novos com o seu objetivo, nível e equipamentos, '
            'mantendo o foco de cada dia.',
        day: day,
        run: (a, only) => a.changePlan(onlyDay: only),
        footer: Builder(
          builder: (ctx) => TextButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              openPlanner(context);
            },
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Ajustar objetivo, nível e tempo'),
          ),
        ),
      ),
    );

/// "Evoluir": próxima versão do plano (carga, exercícios, tempo e dificuldade).
Future<void> showEvolveSheet(
  BuildContext context, {
  required int day,
  required bool dayHasWorkout,
}) => _open(
  context,
  _PlanSheet(
    title: 'Evoluir plano',
    intro: 'Cria a próxima versão do que você já treina:',
    bullets: const [
      'Carga: sobe a partir da última que você usou',
      'Exercícios: mantém os 2 principais e troca o resto por variações',
      'Tempo: +1 série, descanso menor e cardio mais longo',
      'Dificuldade: sobe de nível a cada 2 evoluções da semana',
    ],
    day: day,
    dayEnabled: dayHasWorkout,
    run: (a, only) => a.evolvePlan(onlyDay: only),
  ),
);

Future<void> _open(BuildContext context, Widget sheet) async {
  final actions = context.read<PlanActions>();
  final messenger = ScaffoldMessenger.of(context);
  final change = await showModalBottomSheet<PlanChange>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => sheet,
  );
  if (change == null) return;
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(change.summary),
        duration: const Duration(seconds: 8),
        // Com ação, o SnackBar não some sozinho a menos que persist seja false.
        persist: false,
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => actions.undo(change),
        ),
      ),
    );
}

class _PlanSheet extends StatefulWidget {
  final String title, intro;
  final List<String> bullets;
  final int day;
  final bool dayEnabled;
  final Future<PlanChange?> Function(PlanActions actions, int? onlyDay) run;
  final Widget? footer;

  const _PlanSheet({
    required this.title,
    required this.intro,
    required this.day,
    required this.run,
    this.bullets = const [],
    this.dayEnabled = true,
    this.footer,
  });

  @override
  State<_PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends State<_PlanSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _choose(int? onlyDay) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final change = await widget.run(context.read<PlanActions>(), onlyDay);
    if (!mounted) return;
    if (change == null) {
      setState(() {
        _busy = false;
        _error =
            'Não foi possível: escolha seus equipamentos e dias de treino.';
      });
      return;
    }
    Navigator.of(context).pop(change);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title.toUpperCase(), style: AppText.display(38)),
            const SizedBox(height: 6),
            Text(widget.intro, style: TextStyle(color: p.muted, fontSize: 15)),
            for (final b in widget.bullets)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: p.highlight,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(b, style: const TextStyle(height: 1.3)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            if (_busy)
              AppCard(
                color: p.volt,
                borderColor: Colors.transparent,
                child: Row(
                  children: [
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: p.onVolt,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Montando seu treino...',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: p.onVolt,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              _Option(
                icon: Icons.today_rounded,
                title: 'Só ${weekdayFull[widget.day - 1]}',
                subtitle: widget.dayEnabled
                    ? 'Muda apenas o dia que você está vendo'
                    : 'Esse dia ainda não tem treino',
                enabled: widget.dayEnabled,
                onTap: () => _choose(widget.day),
              ),
              const SizedBox(height: 10),
              _Option(
                icon: Icons.calendar_month_rounded,
                title: 'Todos os dias',
                subtitle: 'Refaz a semana inteira',
                onTap: () => _choose(null),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: TextStyle(color: p.danger)),
              ),
            if (widget.footer != null && !_busy)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: widget.footer,
              ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool enabled;
  final VoidCallback onTap;
  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Opacity(
      opacity: enabled ? 1 : .45,
      child: AppCard(
        onTap: enabled ? onTap : null,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: p.volt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: p.onVolt),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.toUpperCase(), style: AppText.display(26)),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: p.muted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.muted),
          ],
        ),
      ),
    );
  }
}
