import 'package:flutter/material.dart';

import 'animated_frames.dart';
import 'gif_view.dart';
import 'illustration/illustration.dart';

/// Mostra o primeiro GIF da lista que carregar; se nenhum carregar (ou não
/// houver), mostra o desenho do aparelho. Com [still], usa miniaturas
/// estáticas (para listas).
Widget equipmentMedia({
  required List<String> gifs,
  required String kind,
  required Color color,
  required double height,
  bool still = false,
  String? photo,
  String? photoId,
}) {
  // GIF animado → foto do exercício → desenho (só quando não há nada).
  final drawing = Illustration(kind, color: color, height: height);
  // Foto de pessoa: nas miniaturas de lista fica parada (1º quadro, leve); nos
  // cartões grandes alterna os dois quadros, como um GIF.
  final fallback = photo == null
      ? drawing
      : Container(
          width: height,
          height: height,
          color: Colors.white,
          child: !still && photoId != null
              ? AnimatedFrames(photoId, height: height, fit: BoxFit.contain)
              : Image.network(
                  photo,
                  key: ValueKey(photo),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => drawing,
                ),
        );
  Widget chain(int i) => i >= gifs.length
      ? fallback
      : still
      ? GifThumb(gifs[i], size: height, fallback: chain(i + 1))
      : GifView(gifs[i], height: height, fallback: chain(i + 1));
  return chain(0);
}
