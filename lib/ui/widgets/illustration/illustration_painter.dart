import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'illustration_kinds.dart';

const illustrationInk = Color(0xFF3B3A4A);
const illustrationGrey = Color(0xFFE4E1EE);

class IllustrationPainter extends CustomPainter {
  final String kind;
  final Animation<double> anim;
  final Color accent;
  IllustrationPainter(this.kind, this.anim, this.accent) : super(repaint: anim);

  late Canvas c;
  late double t;
  late Color accent2 = Color.lerp(accent, illustrationInk, .3)!;

  Paint get inkLine => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round
    ..color = illustrationInk;

  void rr(double x, double y, double w, double h, double r, Color fill) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, h),
      Radius.circular(r),
    );
    c.drawRRect(rect, Paint()..color = fill);
    c.drawRRect(rect, inkLine);
  }

  void circle(double x, double y, double r, Color fill) {
    c.drawCircle(Offset(x, y), r, Paint()..color = fill);
    c.drawCircle(Offset(x, y), r, inkLine);
  }

  void limb(Offset a, Offset b, Color fill, [double w = 5]) {
    c.drawLine(a, b, inkLine..strokeWidth = w + 2.6);
    c.drawLine(
      a,
      b,
      Paint()
        ..color = fill
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round,
    );
  }

  void floor([double y = 34]) =>
      c.drawLine(Offset(-46, y), Offset(46, y), inkLine..strokeWidth = 1.5);

  void dumbbell(double dx, double dy, double rot, double s) {
    c.save();
    c.translate(dx, dy);
    c.rotate(rot);
    c.scale(s);
    rr(-14, -2, 28, 4, 2, illustrationGrey);
    for (final sx in [-1.0, 1.0]) {
      rr(sx > 0 ? 14 : -20, -11, 6, 22, 3, accent2);
      rr(sx > 0 ? 20 : -25, -7, 5, 14, 2.5, accent);
    }
    c.restore();
  }

  void stackWeights(double x, int lifted, double lift) {
    for (var i = 0; i < 6; i++) {
      final up = i < lifted ? lift : 0.0;
      rr(
        x,
        -28.0 + i * 9 - up,
        16,
        7,
        2,
        i < lifted ? accent : illustrationGrey,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    c = canvas;
    t = Curves.easeInOut.transform(anim.value);
    final u = math.min(size.width, size.height) / 100;
    c.translate(size.width / 2, size.height / 2);
    c.scale(u);
    drawKind();
  }

  @override
  bool shouldRepaint(IllustrationPainter old) =>
      old.kind != kind || old.accent != accent;
}
