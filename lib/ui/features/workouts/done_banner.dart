import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../widgets/app_card.dart';

class DoneBanner extends StatelessWidget {
  final VoidCallback onFinish;
  const DoneBanner({required this.onFinish, super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: AppCard(
        borderColor: p.highlight,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Icon(Icons.emoji_events_rounded, size: 60, color: p.warn),
            ),
            const SizedBox(height: 8),
            const Text(
              'Treino concluído!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Salve para marcar o dia no calendário de progresso.',
              style: TextStyle(color: p.muted),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onFinish,
              icon: const Icon(Icons.event_available_rounded),
              label: const Text('Salvar no calendário'),
            ),
          ],
        ),
      ),
    );
  }
}
