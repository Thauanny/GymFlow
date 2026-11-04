import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text.dart';

const double contentMaxWidth = 1040;

/// Página rolável com título grande, centralizada e com largura máxima.
class PageBody extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> children;
  final Widget? bottom;

  const PageBody({
    required this.title,
    required this.children,
    this.subtitle,
    this.actions = const [],
    this.bottom,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Column(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: contentMaxWidth),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  narrow ? 16 : 28,
                  narrow ? 20 : 32,
                  narrow ? 16 : 28,
                  40,
                ),
                children: [
                  if (title.isNotEmpty) ...[
                    _Header(title, subtitle, actions, narrow),
                    SizedBox(height: narrow ? 20 : 28),
                  ],
                  ...children,
                ],
              ),
            ),
          ),
        ),
        ?bottom,
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool narrow;
  const _Header(this.title, this.subtitle, this.actions, this.narrow);

  @override
  Widget build(BuildContext context) {
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: AppText.display(narrow ? 40 : 56)),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              subtitle!,
              style: TextStyle(
                color: context.pal.muted,
                fontSize: narrow ? 14 : 15.5,
              ),
            ),
          ),
      ],
    );
    if (actions.isEmpty) return texts;
    // No celular os botões descem para baixo do título (não estouram a linha).
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          texts,
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: texts),
        Wrap(spacing: 8, runSpacing: 8, children: actions),
      ],
    );
  }
}
