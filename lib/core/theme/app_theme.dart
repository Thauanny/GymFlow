import 'package:flutter/material.dart';
import 'app_palette.dart';
import 'app_text.dart';

ThemeData buildTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  final scheme = ColorScheme.fromSeed(seedColor: p.volt, brightness: brightness)
      .copyWith(
        primary: p.accent,
        onPrimary: p.onAccent,
        secondaryContainer: p.volt,
        onSecondaryContainer: p.onVolt,
        surface: p.card,
        onSurface: p.text,
        outline: p.border,
        error: p.danger,
      );
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  // Tipografia Material completa (com tamanhos) para poder escalar a fonte.
  final typography = Typography.material2021();
  final raw =
      (brightness == Brightness.dark ? typography.white : typography.black)
          .merge(typography.englishLike);
  // Barlow é um pouco menor que as fontes padrão: ampliamos levemente.
  final body = raw.apply(
    fontFamily: bodyFont,
    fontSizeFactor: 1.07,
    bodyColor: p.text,
    displayColor: p.text,
  );
  final text = body.copyWith(
    headlineMedium: AppText.display(38, color: p.text),
    titleLarge: AppText.display(26, color: p.text),
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  final button = text.labelLarge?.copyWith(fontWeight: FontWeight.w700);

  return base.copyWith(
    colorScheme: scheme,
    extensions: [p],
    scaffoldBackgroundColor: p.bg,
    textTheme: text,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: text.titleLarge,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: p.card,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: p.border),
      ),
    ),
    dividerTheme: DividerThemeData(color: p.border, space: 1, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.card,
      hintStyle: TextStyle(color: p.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.text, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        disabledBackgroundColor: p.cardAlt,
        disabledForegroundColor: p.muted,
        minimumSize: const Size(52, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: shape,
        textStyle: button,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.text,
        side: BorderSide(color: p.border, width: 1.4),
        minimumSize: const Size(52, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: shape,
        textStyle: button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.text,
        shape: shape,
        textStyle: button,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: p.text),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.card,
      selectedColor: p.volt,
      side: BorderSide(color: p.border),
      shape: const StadiumBorder(),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      labelStyle: TextStyle(fontWeight: FontWeight.w600, color: p.text),
      secondaryLabelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: p.onVolt,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.card,
      height: 68,
      indicatorColor: p.volt,
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? p.onVolt : p.muted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: s.contains(WidgetState.selected) ? p.text : p.muted,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.volt,
      linearTrackColor: p.cardAlt,
      circularTrackColor: p.cardAlt,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: p.volt,
      thumbColor: p.volt,
      inactiveTrackColor: p.cardAlt,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.onVolt : p.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.volt : p.cardAlt,
      ),
      trackOutlineColor: WidgetStatePropertyAll(p.border),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: p.card,
        selectedBackgroundColor: p.volt,
        selectedForegroundColor: p.onVolt,
        foregroundColor: p.text,
        side: BorderSide(color: p.border),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.accent,
      contentTextStyle: TextStyle(
        color: p.onAccent,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      actionTextColor: p.onAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    listTileTheme: ListTileThemeData(shape: shape),
  );
}
