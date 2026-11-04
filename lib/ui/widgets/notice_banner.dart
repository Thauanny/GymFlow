import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Aviso com botão de ação (ex.: "escolha seus equipamentos"). Em telas
/// estreitas o botão desce para baixo do texto.
class NoticeBanner extends StatelessWidget {
  final String text, action;
  final VoidCallback onTap;
  final IconData icon;

  const NoticeBanner({
    required this.text,
    required this.action,
    required this.onTap,
    this.icon = Icons.info_outline_rounded,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final button = FilledButton(onPressed: onTap, child: Text(action));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.warn.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.warn.withValues(alpha: .4)),
      ),
      child: LayoutBuilder(
        builder: (_, c) {
          final narrow = c.maxWidth < 440;
          final message = Row(
            children: [
              Icon(icon, color: p.warn),
              const SizedBox(width: 12),
              Expanded(child: Text(text)),
              if (!narrow) ...[const SizedBox(width: 8), button],
            ],
          );
          if (!narrow) return message;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [message, const SizedBox(height: 10), button],
          );
        },
      ),
    );
  }
}
