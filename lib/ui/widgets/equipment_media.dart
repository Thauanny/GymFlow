import 'package:flutter/material.dart';

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
}) {
  Widget chain(int i) => i >= gifs.length
      ? Illustration(kind, color: color, height: height)
      : still
      ? GifThumb(gifs[i], size: height, fallback: chain(i + 1))
      : GifView(gifs[i], height: height, fallback: chain(i + 1));
  return chain(0);
}
