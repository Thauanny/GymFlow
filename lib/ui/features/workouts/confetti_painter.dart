import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Confete exibido ao concluir todos os exercícios.
class ConfettiPainter extends CustomPainter {
  final double t;
  final List<Color> colors;
  ConfettiPainter(this.t, this.colors);

  static final _rnd = math.Random(7);
  static final _parts = [
    for (var i = 0; i < 60; i++)
      (
        x: _rnd.nextDouble(),
        vx: (_rnd.nextDouble() - .5) * 320,
        vy: -200 - _rnd.nextDouble() * 320,
        size: 5 + _rnd.nextDouble() * 6,
        rot: _rnd.nextDouble() * math.pi,
      ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final sec = t * 2.2;
    for (final (i, p) in _parts.indexed) {
      final x = p.x * size.width + p.vx * sec;
      final y = size.height * .55 + p.vy * sec + 520 * sec * sec;
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(
          alpha: (1 - t).clamp(0, 1),
        );
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rot + sec * 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 1.6,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter old) => old.t != t;
}
