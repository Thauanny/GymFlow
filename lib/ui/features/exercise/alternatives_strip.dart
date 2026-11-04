import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/alternatives_service.dart';
import '../../../data/alt.dart';
import '../../../models/labels.dart';
import '../../widgets/gif_view.dart';

/// Faixa horizontal com variações do exercício em outros equipamentos.
class AlternativesStrip extends StatelessWidget {
  final List<Alt> alts;
  final ValueChanged<Alt> onOpen;
  const AlternativesStrip({
    required this.alts,
    required this.onOpen,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sem esse aparelho? Faça de outra forma',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          'Variações para o mesmo músculo; as do seu equipamento vêm primeiro.',
          style: TextStyle(fontSize: 12, color: p.muted),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: alts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _AltTile(alts[i], () => onOpen(alts[i])),
          ),
        ),
      ],
    );
  }
}

class _AltTile extends StatelessWidget {
  final Alt alt;
  final VoidCallback onTap;
  const _AltTile(this.alt, this.onTap);

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: p.cardAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: alt.have ? p.highlight : p.border,
            width: alt.have ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GifView(alt.gif, height: 110),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Text(
                context.read<AlternativesService>().altNamePt(alt),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
              child: Text(
                alt.have
                    ? '${equipLabel(alt.equip)} · você tem'
                    : equipLabel(alt.equip),
                style: TextStyle(
                  fontSize: 11,
                  color: alt.have ? p.highlight : p.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
