import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/equipment/equipment_matcher.dart';
import '../../../models/exercise.dart';
import '../../widgets/animated_frames.dart';
import '../../widgets/gif_view.dart';
import '../../widgets/illustration/illustration.dart';

/// Tipos de imagem de um exercício.
enum MediaKind {
  animation(
    'Animação',
    Icons.animation_rounded,
    'Animação do movimento, com os músculos trabalhados em destaque.',
  ),
  photos(
    'Pessoa',
    Icons.person_rounded,
    'Fotos reais de uma pessoa nas duas posições do movimento.',
  ),
  drawing(
    'Desenho',
    Icons.draw_rounded,
    'Desenho animado do aparelho usado no exercício.',
  );

  final String label, caption;
  final IconData icon;
  const MediaKind(this.label, this.icon, this.caption);
}

/// Mostra o exercício como animação (padrão), fotos de pessoas ou desenho.
class ExerciseMedia extends StatefulWidget {
  final Exercise exercise;
  final String? gif;
  const ExerciseMedia(this.exercise, this.gif, {super.key});

  @override
  State<ExerciseMedia> createState() => _ExerciseMediaState();
}

class _ExerciseMediaState extends State<ExerciseMedia> {
  MediaKind? _chosen;

  List<MediaKind> get _available => [
    if (widget.gif != null) MediaKind.animation,
    if (widget.exercise.images.isNotEmpty) MediaKind.photos,
    MediaKind.drawing,
  ];

  MediaKind get _kind => _chosen != null && _available.contains(_chosen)
      ? _chosen!
      : _available.first;

  Widget _media(BuildContext context, MediaKind kind) {
    final e = widget.exercise;
    return switch (kind) {
      MediaKind.animation => GifView(widget.gif!, height: 280, lite: false),
      MediaKind.photos => AnimatedFrames(e.id, height: 280),
      MediaKind.drawing => Illustration(
        itemForExercise(e)?.kind ?? 'body',
        color: context.pal.tints[2],
        height: 280,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final kind = _kind;
    final p = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: KeyedSubtree(
            key: ValueKey('${widget.exercise.id}-${kind.name}'),
            child: _media(context, kind),
          ),
        ),
        const SizedBox(height: 12),
        if (_available.length > 1)
          _MediaTabs(
            kinds: _available,
            selected: kind,
            onSelect: (k) => setState(() => _chosen = k),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            kind.caption,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: p.muted),
          ),
        ),
      ],
    );
  }
}

/// Abas de tipo de imagem: ícone em cima e legenda embaixo (cabem em qualquer
/// largura, sem quebrar a palavra no meio).
class _MediaTabs extends StatelessWidget {
  final List<MediaKind> kinds;
  final MediaKind selected;
  final ValueChanged<MediaKind> onSelect;
  const _MediaTabs({
    required this.kinds,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      children: [
        for (final (i, k) in kinds.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onSelect(k),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 58,
                decoration: BoxDecoration(
                  color: k == selected ? p.volt : p.cardAlt,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      k.icon,
                      size: 20,
                      color: k == selected ? p.onVolt : p.muted,
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        k.label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: k == selected ? p.onVolt : p.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
