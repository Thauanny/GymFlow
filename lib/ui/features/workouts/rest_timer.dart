import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/format.dart';

/// Cronômetro de descanso entre séries.
Future<void> showRestTimer(BuildContext context, int seconds) =>
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _RestTimer(seconds),
    );

class _RestTimer extends StatefulWidget {
  final int seconds;
  const _RestTimer(this.seconds);

  @override
  State<_RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<_RestTimer> {
  late int _left = widget.seconds;
  late final int _total = widget.seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left <= 1) {
        t.cancel();
        HapticFeedback.heavyImpact();
      }
      setState(() => _left = (_left - 1).clamp(0, 9999));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final done = _left == 0;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              done ? 'Descanso concluído' : 'Descansando',
              style: TextStyle(color: p.muted),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: _total == 0 ? 0 : _left / _total,
                    strokeWidth: 8,
                    color: done ? p.highlight : p.accent,
                  ),
                  Center(
                    child: Text(
                      formatClock(_left),
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _left += 15),
                    child: const Text('+15 s'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(done ? 'Próxima série' : 'Pular'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
