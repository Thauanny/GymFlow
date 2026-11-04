import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/equipment/equipment_catalog.dart';
import '../../widgets/equipment_media.dart';

/// Cartão de um aparelho: toque no cartão para marcar, lupa para ver como usar.
class EquipCard extends StatelessWidget {
  final EquipItem item;
  final List<String> gifs;
  final int count;
  final bool selected;
  final Color tint;
  final VoidCallback onToggle, onInfo, onAlternatives;

  const EquipCard({
    required this.item,
    required this.gifs,
    required this.count,
    required this.selected,
    required this.tint,
    required this.onToggle,
    required this.onInfo,
    required this.onAlternatives,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final radius = BorderRadius.circular(22);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: radius,
        border: Border.all(
          color: selected ? p.accent : p.border,
          width: selected ? 2.2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    // Toque na imagem inteira para ver os detalhes (alvo grande).
                    InkWell(
                      onTap: onInfo,
                      child: equipmentMedia(
                        gifs: gifs,
                        kind: item.kind,
                        color: tint,
                        height: 138,
                      ),
                    ),
                    // Marcar/desmarcar: área de toque de 48 px em volta do círculo.
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Semantics(
                        button: true,
                        label: selected
                            ? 'Desmarcar aparelho'
                            : 'Marcar aparelho',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onToggle,
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(child: _Check(selected)),
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      bottom: 8,
                      right: 8,
                      child: IgnorePointer(child: _ZoomBadge()),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        height: 34,
                        child: Text(
                          item.desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: p.muted),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$count exercícios',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: p.text.withValues(alpha: .75),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Ver alternativas',
                            visualDensity: VisualDensity.compact,
                            onPressed: onAlternatives,
                            icon: Icon(
                              Icons.swap_horiz_rounded,
                              size: 22,
                              color: p.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  final bool selected;
  const _Check(this.selected);

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? p.volt : Colors.white.withValues(alpha: .9),
        border: Border.all(
          color: selected ? p.onVolt : Colors.black26,
          width: selected ? 0 : 1.5,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: 18, color: p.onVolt)
          : null,
    );
  }
}

/// Indicador visual de "toque para ampliar" (o toque é na imagem inteira).
class _ZoomBadge extends StatelessWidget {
  const _ZoomBadge();

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 17,
      backgroundColor: Colors.white.withValues(alpha: .92),
      child: const Icon(Icons.zoom_in_rounded, size: 22, color: Colors.black87),
    );
  }
}
