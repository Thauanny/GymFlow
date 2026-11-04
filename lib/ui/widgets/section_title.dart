import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text.dart';

/// Título de seção; com [step] mostra o número da etapa em destaque.
/// Em telas estreitas o [trailing] desce para baixo do título.
class SectionTitle extends StatelessWidget {
  final String title;
  final String? hint;
  final Widget? trailing;
  final int? step;

  const SectionTitle(
    this.title, {
    this.hint,
    this.trailing,
    this.step,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 14),
      child: LayoutBuilder(
        builder: (_, c) {
          final stacked = trailing != null && c.maxWidth < 460;
          final head = Row(
            children: [
              if (step != null) ...[_Step(step!), const SizedBox(width: 12)],
              Expanded(child: _Texts(title, hint)),
              if (trailing != null && !stacked) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          );
          if (!stacked) return head;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              head,
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft, child: trailing),
            ],
          );
        },
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  const _Step(this.number);

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: p.volt, shape: BoxShape.circle),
      child: Text('$number', style: AppText.display(18, color: p.onVolt)),
    );
  }
}

class _Texts extends StatelessWidget {
  final String title;
  final String? hint;
  const _Texts(this.title, this.hint);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: AppText.display(26)),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              hint!,
              style: TextStyle(fontSize: 13, color: context.pal.muted),
            ),
          ),
      ],
    );
  }
}
