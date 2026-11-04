import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'illustration_painter.dart';

/// Desenho de cada tipo de equipamento.
extension IllustrationKinds on IllustrationPainter {
  void drawKind() {
    switch (kind) {
      case 'barbell':
        final dy = 4 - t * 12;
        rr(-46, dy - 1.5, 92, 3, 1.5, illustrationGrey);
        for (final sx in [-1.0, 1.0]) {
          rr(sx * 30 - 3, dy - 18, 6, 36, 3, accent);
          rr(sx * 37 - 2.5, dy - 12, 5, 24, 2.5, accent2);
        }
        floor();
      case 'ezbar':
        final dy = 4 - t * 8;
        final path = Path();
        for (var x = -40.0; x <= 40; x += 2) {
          final y = dy + math.sin(x * .22) * 4;
          x == -40 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        c.drawPath(path, inkLine..strokeWidth = 6);
        c.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.4
            ..color = illustrationGrey,
        );
        for (final sx in [-1.0, 1.0]) {
          rr(sx * 42 - 2.5, dy - 9, 5, 18, 2.5, accent);
        }
        floor();
      case 'kettlebell':
        c.save();
        c.translate(0, 30);
        c.rotate((t - .5) * .6);
        c.translate(0, -30);
        final handle = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-11, -34, 22, 26),
          const Radius.circular(10),
        );
        c.drawRRect(handle, inkLine..strokeWidth = 7);
        c.drawRRect(
          handle,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..color = illustrationGrey,
        );
        circle(0, 10, 21, accent);
        c.drawOval(
          const Rect.fromLTWH(-13, -2, 9, 6),
          Paint()..color = Colors.white.withValues(alpha: .7),
        );
        c.restore();
        floor();
      case 'bench':
        rr(-38, 8, 76, 12, 5, accent);
        rr(-30, 20, 6, 18, 2, illustrationGrey);
        rr(24, 20, 6, 18, 2, illustrationGrey);
        dumbbell(0, -14 - t * 14, 0, 1);
        floor(38);
      case 'rack':
        rr(-34, -40, 6, 78, 2, illustrationGrey);
        rr(28, -40, 6, 78, 2, illustrationGrey);
        rr(-42, 36, 22, 4, 2, accent2);
        rr(20, 36, 22, 4, 2, accent2);
        final dy = -8 + t * 6;
        rr(-46, dy - 1.5, 92, 3, 1.5, illustrationGrey);
        for (final sx in [-1.0, 1.0]) {
          rr(sx * 40 - 3, dy - 13, 6, 26, 3, accent);
        }
      case 'stack':
        rr(-38, -22, 8, 34, 4, accent2);
        rr(-38, 12, 26, 7, 3, accent);
        rr(-40, 30, 80, 5, 2, illustrationGrey);
        c.drawLine(
          const Offset(15, -34),
          const Offset(15, 30),
          inkLine..strokeWidth = 1.3,
        );
        c.drawLine(
          const Offset(29, -34),
          const Offset(29, 30),
          inkLine..strokeWidth = 1.3,
        );
        stackWeights(14, 3, t * 8);
        final hy = -20 + t * 8;
        c.drawLine(
          Offset(22, -30 - t * 8),
          Offset(-14, hy),
          inkLine..strokeWidth = 1.4,
        );
        rr(-21, hy - 1.5, 14, 3.5, 1.7, illustrationGrey);
        circle(22, -34, 3, illustrationGrey);
      case 'plate':
        c.drawLine(
          const Offset(-40, 32),
          const Offset(34, -22),
          inkLine..strokeWidth = 7,
        );
        c.drawLine(
          const Offset(-40, 32),
          const Offset(34, -22),
          Paint()
            ..strokeWidth = 4
            ..color = illustrationGrey
            ..strokeCap = StrokeCap.round,
        );
        c.drawLine(
          const Offset(-44, 34),
          const Offset(40, 34),
          inkLine..strokeWidth = 1.5,
        );
        final p = Offset.lerp(const Offset(-26, 20), const Offset(16, -10), t)!;
        c.save();
        c.translate(p.dx, p.dy);
        c.rotate(-0.63);
        rr(-14, -10, 28, 8, 3, accent);
        rr(-6, -20, 12, 10, 3, accent2);
        c.restore();
      case 'cable':
        rr(-36, -40, 5, 76, 2, illustrationGrey);
        rr(31, -40, 5, 76, 2, illustrationGrey);
        rr(-36, -40, 72, 5, 2, illustrationGrey);
        circle(-14, -32, 5, accent);
        stackWeights(8, 2, t * 10);
        final hy = -8 + t * 26;
        c.drawLine(
          Offset(-14, -27),
          Offset(-14, hy),
          inkLine..strokeWidth = 1.4,
        );
        rr(-24, hy, 20, 4, 2, accent2);
        floor(38);
      case 'bands':
        final rx = 20 + t * 18;
        final oval = Rect.fromCenter(
          center: Offset.zero,
          width: rx * 2,
          height: 22,
        );
        c.drawOval(oval, inkLine..strokeWidth = 8);
        c.drawOval(
          oval,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..color = accent2,
        );
        circle(-rx, 0, 4.5, illustrationGrey);
        circle(rx, 0, 4.5, illustrationGrey);
      case 'medball':
        final y = 14 - 34 * math.sin(math.pi * t);
        c.drawOval(
          Rect.fromCenter(
            center: const Offset(0, 36),
            width: 34 - (14 - y) * .3,
            height: 6,
          ),
          Paint()..color = illustrationInk.withValues(alpha: .15),
        );
        circle(0, y, 19, accent);
        final seam = Path()
          ..moveTo(-19, y)
          ..quadraticBezierTo(0, y + 8, 19, y)
          ..moveTo(0, y - 19)
          ..quadraticBezierTo(8, y, 0, y + 19);
        c.drawPath(seam, inkLine..strokeWidth = 1.6);
      case 'swissball':
        final y = 4 - 16 * math.sin(math.pi * t);
        c.drawOval(
          Rect.fromCenter(center: const Offset(0, 36), width: 44, height: 6),
          Paint()..color = illustrationInk.withValues(alpha: .15),
        );
        circle(0, y, 27, accent);
        c.drawOval(
          Rect.fromCenter(center: Offset(-10, y - 12), width: 12, height: 7),
          Paint()..color = Colors.white.withValues(alpha: .7),
        );
      case 'foam':
        final x = (t - .5) * 24;
        rr(x - 30, -12, 60, 26, 13, accent);
        for (var i = -1; i <= 1; i++) {
          c.drawLine(
            Offset(x + i * 14.0, -10),
            Offset(x + i * 14.0, 12),
            inkLine..strokeWidth = 1.4,
          );
        }
        floor(20);
      case 'body':
        rr(-32, -42, 64, 4, 2, illustrationGrey);
        rr(-34, -42, 3, 74, 1, illustrationGrey);
        rr(31, -42, 3, 74, 1, illustrationGrey);
        final dy = (1 - t) * 14;
        limb(Offset(-9, -38), Offset(-3, -20 + dy), accent2, 4);
        limb(Offset(9, -38), Offset(3, -20 + dy), accent2, 4);
        limb(Offset(0, -12 + dy), Offset(0, 10 + dy), accent, 8);
        limb(Offset(0, 10 + dy), Offset(-5, 30 + dy), accent2, 5);
        limb(Offset(0, 10 + dy), Offset(5, 30 + dy), accent2, 5);
        circle(0, -18 + dy, 6.5, const Color(0xFFFFE3D0));
      case 'abwheel':
        final x = (t - .5) * 36;
        c.drawLine(
          Offset(x - 20, 14),
          Offset(x + 20, 14),
          inkLine..strokeWidth = 3.5,
        );
        circle(x, 14, 13, accent);
        circle(x, 14, 4, illustrationGrey);
        floor(28);
      case 'cardio':
        rr(-40, 20, 72, 8, 4, illustrationGrey);
        for (var i = 0; i < 5; i++) {
          final x = -36 + ((i * 14 + t * 14) % 70);
          c.drawLine(
            Offset(x, 24),
            Offset(x + 4, 24),
            Paint()
              ..color = Colors.white
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round,
          );
        }
        rr(26, -30, 5, 50, 2, illustrationGrey);
        rr(14, -36, 24, 9, 3, accent);
        final sw = (t - .5) * 16;
        limb(const Offset(-8, -6), const Offset(-8, 8), accent, 7);
        limb(const Offset(-8, 8), Offset(-8 + sw, 20), accent2, 5);
        limb(const Offset(-8, 8), Offset(-8 - sw, 20), accent2, 5);
        limb(const Offset(-8, -4), Offset(-8 - sw, 4), accent2, 4);
        circle(-8, -14, 6.5, const Color(0xFFFFE3D0));
      default:
        dumbbell(0, 0, (t - .5) * .7, 1.5);
    }
  }
}
