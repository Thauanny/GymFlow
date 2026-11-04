import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Etiqueta pequena e arredondada.
class Pill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;

  const Pill(this.label, {this.icon, this.color, super.key});

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.pal.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: c),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: c,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
