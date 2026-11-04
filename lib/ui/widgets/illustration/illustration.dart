import 'package:flutter/material.dart';

import 'illustration_painter.dart';

class Illustration extends StatefulWidget {
  final String kind;
  final Color color;
  final double height;
  const Illustration(
    this.kind, {
    required this.color,
    this.height = 120,
    super.key,
  });

  @override
  State<Illustration> createState() => _IllustrationState();
}

class _IllustrationState extends State<Illustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      color: widget.color.withValues(alpha: .45),
      child: CustomPaint(
        painter: IllustrationPainter(widget.kind, ctrl, widget.color),
      ),
    );
  }
}
