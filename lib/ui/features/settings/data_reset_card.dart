import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/backup/data_reset.dart';
import '../../widgets/app_card.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/toast.dart';

class _Option {
  final ResetScope scope;
  final IconData icon;
  final String title, subtitle, question, message, confirm, done;
  final bool danger;
  const _Option({
    required this.scope,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.question,
    required this.message,
    required this.confirm,
    required this.done,
    this.danger = false,
  });
}

const _options = [
  _Option(
    scope: ResetScope.workouts,
    icon: Icons.fitness_center_rounded,
    title: 'Apagar treinos',
    subtitle:
        'Semana, planos anteriores e treinos gerados. Mantém o histórico, o calendário e o peso.',
    question: 'Apagar todos os treinos?',
    message:
        'A semana, os dias de treino, os planos anteriores e os treinos '
        'gerados serão apagados. O histórico de treinos feitos (calendário e '
        'progresso), o peso e os equipamentos continuam salvos. Não dá para '
        'desfazer.',
    confirm: 'Apagar treinos',
    done: 'Treinos apagados. O histórico e o progresso foram mantidos.',
  ),
  _Option(
    scope: ResetScope.progress,
    icon: Icons.history_toggle_off_rounded,
    title: 'Apagar progresso',
    subtitle:
        'Histórico de treinos feitos, calendário e cargas. Mantém treinos, equipamentos e peso.',
    question: 'Apagar o progresso?',
    message:
        'O histórico de treinos feitos (calendário, constância e últimos '
        'treinos) e as cargas usadas serão apagados. Seus treinos, o peso e '
        'os equipamentos continuam salvos. Não dá para desfazer.',
    confirm: 'Apagar progresso',
    done: 'Progresso apagado. Seus treinos foram mantidos.',
  ),
  _Option(
    scope: ResetScope.workoutsAndProgress,
    icon: Icons.event_busy_rounded,
    title: 'Apagar treinos e progresso',
    subtitle:
        'Treinos mais o histórico, o calendário e as cargas. Mantém equipamentos e peso.',
    question: 'Apagar treinos e progresso?',
    message:
        'A semana, os planos anteriores, os treinos gerados, o histórico de '
        'treinos feitos (calendário, constância e últimos treinos) e as cargas '
        'usadas serão apagados. Peso e equipamentos continuam salvos. Não dá '
        'para desfazer.',
    confirm: 'Apagar tudo isso',
    done: 'Treinos e progresso apagados.',
  ),
  _Option(
    scope: ResetScope.weight,
    icon: Icons.monitor_weight_outlined,
    title: 'Apagar peso corporal',
    subtitle: 'Todos os registros de peso e o gráfico.',
    question: 'Apagar o peso corporal?',
    message:
        'Todos os registros de peso e o gráfico serão apagados. Treinos e '
        'progresso continuam. Não dá para desfazer.',
    confirm: 'Apagar peso',
    done: 'Peso corporal apagado.',
  ),
  _Option(
    scope: ResetScope.equipment,
    icon: Icons.precision_manufacturing_outlined,
    title: 'Apagar máquinas e exercícios',
    subtitle: 'Equipamentos e halteres escolhidos. Mantém treinos e progresso.',
    question: 'Apagar máquinas e exercícios?',
    message:
        'Os equipamentos e halteres escolhidos (e os aparelhos a evitar) '
        'serão apagados. Nenhum exercício ficará disponível até você escolher '
        'de novo. Seus treinos salvos continuam. Não dá para desfazer.',
    confirm: 'Apagar',
    done: 'Máquinas e exercícios apagados.',
  ),
  _Option(
    scope: ResetScope.all,
    icon: Icons.delete_forever_rounded,
    title: 'Apagar tudo',
    subtitle: 'Treinos, equipamentos, progresso, peso e preferências.',
    question: 'Apagar todos os dados?',
    message:
        'Tudo será apagado deste navegador: treinos, equipamentos, progresso, '
        'peso e preferências. Não dá para desfazer. Exporte um backup antes '
        'se quiser guardar uma cópia.',
    confirm: 'Apagar tudo',
    done: 'Todos os dados foram apagados.',
    danger: true,
  ),
];

/// "Apagar dados": treinos (com ou sem progresso), peso, máquinas ou tudo.
class DataResetCard extends StatelessWidget {
  const DataResetCard({super.key});

  Future<void> _ask(BuildContext context, _Option o) async {
    final service = context.read<DataResetService>();
    final ok = await confirmDialog(
      context,
      title: o.question,
      message: o.message,
      confirm: o.confirm,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    await service.reset(o.scope);
    if (context.mounted) showToast(context, o.done);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: Text(
                'Apague partes dos dados salvos neste navegador. Não dá para '
                'desfazer: exporte um backup antes se quiser guardar uma cópia.',
                style: TextStyle(color: p.muted, height: 1.35),
              ),
            ),
            for (final o in _options) ...[
              Divider(height: 1, color: p.border),
              _Row(o, onTap: () => _ask(context, o)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final _Option option;
  final VoidCallback onTap;
  const _Row(this.option, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final o = option;
    final accent = o.danger ? p.danger : p.muted;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: o.danger ? p.danger.withValues(alpha: .12) : p.cardAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(o.icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    o.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: o.danger ? p.danger : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    o.subtitle,
                    style: TextStyle(fontSize: 12.5, color: p.muted),
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
