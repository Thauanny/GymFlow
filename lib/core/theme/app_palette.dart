import 'package:flutter/material.dart';

/// Tokens de cor do app para os temas escuro e claro.
///
/// `accent` é a cor de ação (botões, seleção): lima no escuro, preto no claro.
/// `volt` é o lima de marca, sempre com texto escuro por cima.
class AppPalette extends ThemeExtension<AppPalette> {
  final Color bg, card, cardAlt, border, text, muted;
  final Color accent, onAccent, volt, onVolt, highlight, warn, danger;

  const AppPalette({
    required this.bg,
    required this.card,
    required this.cardAlt,
    required this.border,
    required this.text,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.volt,
    required this.onVolt,
    required this.highlight,
    required this.warn,
    required this.danger,
  });

  static const _volt = Color(0xFFC8FF2E);
  static const _ink = Color(0xFF0B0B0C);

  static const dark = AppPalette(
    bg: _ink,
    card: Color(0xFF151517),
    cardAlt: Color(0xFF1F1F22),
    border: Color(0xFF2B2B2F),
    text: Color(0xFFF5F5F2),
    muted: Color(0xFF8E8E93),
    accent: _volt,
    onAccent: _ink,
    volt: _volt,
    onVolt: _ink,
    highlight: _volt,
    warn: Color(0xFFFF9F0A),
    danger: Color(0xFFFF453A),
  );

  static const light = AppPalette(
    bg: Color(0xFFF7F7F4),
    card: Colors.white,
    cardAlt: Color(0xFFF0F0EA),
    border: Color(0xFFE6E6DF),
    text: _ink,
    muted: Color(0xFF6E6E73),
    accent: _ink,
    onAccent: _volt,
    volt: _volt,
    onVolt: _ink,
    highlight: Color(0xFF2F9E44),
    warn: Color(0xFFC77700),
    danger: Color(0xFFD63A32),
  );

  /// Cores de apoio para diferenciar categorias.
  List<Color> get tints => [
    accent,
    warn,
    const Color(0xFF4DB6F5),
    const Color(0xFFFF7EB6),
    const Color(0xFF9B8CFF),
  ];

  bool get isDark => bg == _ink;

  /// Fundos suaves (pastel no claro) para blocos coloridos, na mesma ordem de [tints].
  List<Color> get softTints => isDark
      ? [for (final c in tints) c.withValues(alpha: .16)]
      : const [
          Color(0xFFEAFBB8),
          Color(0xFFFFE5D0),
          Color(0xFFDDF0FF),
          Color(0xFFFFE0EC),
          Color(0xFFE8E2FF),
        ];

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) =>
      t < .5 ? this : (other as AppPalette? ?? this);
}

extension PaletteContext on BuildContext {
  AppPalette get pal => Theme.of(this).extension<AppPalette>()!;
}
