import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

OverlayEntry? _current;

/// Aviso no topo da tela, que some sozinho. Não cobre botões nem intercepta
/// toques. [error] troca o ícone e a cor de destaque para vermelho.
void showToast(BuildContext context, String message, {bool error = false}) {
  _current?.remove();
  final p = context.pal;
  final textStyle = Theme.of(context).textTheme.bodyMedium!;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Toast(
      message: message,
      palette: p,
      textStyle: textStyle,
      error: error,
      onDone: () {
        if (_current == entry) _current = null;
        entry.remove();
      },
    ),
  );
  _current = entry;
  Overlay.of(context, rootOverlay: true).insert(entry);
}

class _Toast extends StatefulWidget {
  final String message;
  final AppPalette palette;
  final TextStyle textStyle;
  final bool error;
  final VoidCallback onDone;

  const _Toast({
    required this.message,
    required this.palette,
    required this.textStyle,
    required this.error,
    required this.onDone,
  });

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  @override
  void initState() {
    super.initState();
    _anim.forward();
    Future.delayed(const Duration(milliseconds: 2800), () async {
      if (!mounted) return;
      await _anim.reverse();
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final accent = widget.error ? p.danger : p.volt;
    final onAccent = widget.error ? Colors.white : p.onVolt;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: IgnorePointer(
          child: Align(
            alignment: Alignment.topCenter,
            // Sem Material por perto, o Flutter usa um texto vermelho de
            // emergência; o Material transparente aplica o tema corretamente.
            child: Material(
              type: MaterialType.transparency,
              child: FadeTransition(
                opacity: _anim,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, -.5), end: Offset.zero)
                      .animate(
                        CurvedAnimation(
                          parent: _anim,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, left: 16, right: 16),
                    constraints: const BoxConstraints(maxWidth: 460),
                    padding: const EdgeInsets.fromLTRB(10, 10, 20, 10),
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: p.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.error
                                ? Icons.priority_high_rounded
                                : Icons.check_rounded,
                            size: 20,
                            color: onAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: widget.textStyle.copyWith(
                              color: p.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
