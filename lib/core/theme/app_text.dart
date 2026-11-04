import 'package:flutter/material.dart';

/// Famílias de fonte embutidas no app (assets/fonts, licença OFL).
const bodyFont = 'Barlow';
const displayFont = 'BarlowCondensed';

/// Estilos de destaque: títulos e números grandes em fonte condensada.
class AppText {
  static TextStyle display(double size, {Color? color}) => TextStyle(
    fontFamily: displayFont,
    fontSize: size,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: .2,
    color: color,
  );

  /// Rótulo pequeno em caixa alta (títulos de seção).
  static TextStyle eyebrow(Color color) => TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: color,
  );
}
