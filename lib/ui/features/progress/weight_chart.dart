import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../models/history.dart';

/// Gráfico de linha simples do peso corporal.
class WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;
  const WeightChart(this.entries, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SizedBox(
      height: 170,
      child: CustomPaint(
        size: Size.infinite,
        painter: _ChartPainter(entries, p.text, p.volt, p.muted, p.border),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<WeightEntry> data;
  final Color line, dot, label, grid;
  _ChartPainter(this.data, this.line, this.dot, this.label, this.grid);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    const pad = 24.0;
    final lo = data.map((e) => e.kg).reduce((a, b) => a < b ? a : b) - 1;
    final hi = data.map((e) => e.kg).reduce((a, b) => a > b ? a : b) + 1;
    final h = size.height - pad * 2;
    double x(int i) => data.length == 1
        ? size.width / 2
        : pad + i * (size.width - pad * 2) / (data.length - 1);
    double y(double kg) => pad + h - (kg - lo) / (hi - lo) * h;

    canvas.drawLine(
      Offset(0, size.height - pad),
      Offset(size.width, size.height - pad),
      Paint()..color = grid,
    );
    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final o = Offset(x(i), y(data[i].kg));
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
    for (var i = 0; i < data.length; i++) {
      final o = Offset(x(i), y(data[i].kg));
      canvas.drawCircle(o, 7, Paint()..color = line);
      canvas.drawCircle(o, 4.5, Paint()..color = dot);
      _text(canvas, data[i].kg.toStringAsFixed(1), Offset(o.dx, o.dy - 18));
      _text(
        canvas,
        '${data[i].date.day}/${data[i].date.month}',
        Offset(o.dx, size.height - 14),
      );
    }
  }

  void _text(Canvas canvas, String s, Offset center) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(fontSize: 10, color: label),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.data != data || old.line != line;
}
