import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Cartão base do app (borda fina, cantos arredondados, toque opcional).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap, onLongPress;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final double radius;
  final Gradient? gradient;

  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.onLongPress,
    this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.radius = 22,
    this.gradient,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final shape = BorderRadius.circular(radius);
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: gradient == null ? (color ?? p.card) : null,
          gradient: gradient,
          borderRadius: shape,
          border: Border.all(
            color: borderColor ?? p.border,
            width: borderWidth,
          ),
        ),
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
