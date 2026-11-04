import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../models/exercise.dart';

/// Alterna os 2 quadros da foto do exercício (efeito de GIF).
class AnimatedFrames extends StatefulWidget {
  final String imageId;
  final double? height;
  final BoxFit fit;
  const AnimatedFrames(
    this.imageId, {
    this.height,
    this.fit = BoxFit.cover,
    super.key,
  });

  @override
  State<AnimatedFrames> createState() => _AnimatedFramesState();
}

class _AnimatedFramesState extends State<AnimatedFrames> {
  int _frame = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(milliseconds: 800),
      (_) => setState(() => _frame = 1 - _frame),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final f in [0, 1])
            Opacity(
              opacity: _frame == f ? 1 : 0,
              child: Image.network(
                frameUrl(widget.imageId, f),
                fit: widget.fit,
                errorBuilder: (ctx, _, _) => Container(
                  color: ctx.pal.cardAlt,
                  child: const Icon(Icons.fitness_center),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
