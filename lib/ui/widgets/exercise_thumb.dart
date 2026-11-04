import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/responsive.dart';
import '../../data/equipment/equipment_matcher.dart';
import '../../data/gif_catalog.dart';
import '../../models/exercise.dart';
import 'equipment_media.dart';

/// Miniatura do exercício: GIF do próprio exercício, senão as fotos da pessoa,
/// senão o desenho do aparelho. Em telas pequenas, as
/// miniaturas de lista são estáticas (1º quadro); nas demais, animam.
class ExerciseThumb extends StatelessWidget {
  final Exercise exercise;
  final double size;
  const ExerciseThumb(this.exercise, {this.size = 52, super.key});

  @override
  Widget build(BuildContext context) {
    final gifs = context.read<GifCatalog>();
    final item = itemForExercise(exercise);
    // GIF do próprio exercício; sem ele, as fotos da pessoa; só sem nenhuma
    // imagem, o desenho. Nunca o GIF do aparelho (era de outro exercício).
    final own = gifs.gifFor(exercise);
    return ClipRRect(
      key: ValueKey('thumb-${exercise.id}'),
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: size,
        height: size,
        child: equipmentMedia(
          gifs: [?own],
          kind: item?.kind ?? 'body',
          color: context.pal.tints[2],
          height: size,
          still: size <= 72 && isPhone(context),
          photo: exercise.imageUrl,
          photoId: exercise.images.isEmpty ? null : exercise.id,
        ),
      ),
    );
  }
}
