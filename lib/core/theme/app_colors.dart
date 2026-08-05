import 'package:flutter/material.dart';

/// MPC brand palette, extracted directly from globalmpc.tech (theme-color
/// #0c0a09, gold gradient dd854c -> ffd077 -> ffedc1, copper logo #c2773f,
/// muted green #50986b). The brand is dark-first and warm-toned; a clean warm
/// light variant is provided for system light mode.
class AppColors {
  const AppColors._();

  // Brand accents
  static const Color gold = Color(0xFFFFD077); // primary gold
  static const Color goldSoft = Color(0xFFFFEDC1);
  static const Color copper = Color(0xFFC2773F); // logo / deep accent
  static const Color amber = Color(0xFFE28D4F);
  static const Color terracotta = Color(0xFFDD854C);
  static const Color green = Color(0xFF50986B); // muted emerald

  /// Signature metallic gold gradient used on the site for emphasis.
  static const List<Color> goldGradient = [
    Color(0xFFDD854C),
    Color(0xFFFFD077),
    Color(0xFFFFEDC1),
    Color(0xFFFFD077),
    Color(0xFFDD854C),
  ];

  // Semantic
  static const Color positive = Color(0xFF50986B);
  static const Color warning = Color(0xFFE28D4F);
  static const Color danger = Color(0xFFE5533D);
  static const Color info = Color(0xFF6E93C9);

  // Dark scheme (brand default)
  static const Color darkBg = Color(0xFF0C0A09);
  static const Color darkSurface = Color(0xFF16120F);
  static const Color darkSurfaceHi = Color(0xFF211B15);
  static const Color darkBorder = Color(0xFF2C2621);
  static const Color darkTextHi = Color(0xFFF7F3EE);
  static const Color darkTextLo = Color(0xFFA39A92);

  // Light scheme — exchange-app neutrals (Binance-adjacent hierarchy)
  static const Color lightBg = Color(0xFFFCFAF7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceHi = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE8E0D8);
  static const Color lightTextHi = Color(0xFF201A16);
  static const Color lightTextLo = Color(0xFF766C64);
}

/// Semantic tokens resolved per-brightness so widgets never branch on theme.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surfaceHi,
    required this.border,
    required this.textHi,
    required this.textLo,
    required this.primary,
    required this.accent,
  });

  final Color bg;
  final Color surface;
  final Color surfaceHi;
  final Color border;
  final Color textHi;
  final Color textLo;
  final Color primary; // main call-to-action / highlight
  final Color accent; // gold

  static const AppPalette dark = AppPalette(
    bg: AppColors.darkBg,
    surface: AppColors.darkSurface,
    surfaceHi: AppColors.darkSurfaceHi,
    border: AppColors.darkBorder,
    textHi: AppColors.darkTextHi,
    textLo: AppColors.darkTextLo,
    primary: AppColors.gold,
    accent: AppColors.copper,
  );

  static const AppPalette light = AppPalette(
    bg: AppColors.lightBg,
    surface: AppColors.lightSurface,
    surfaceHi: AppColors.lightSurfaceHi,
    border: AppColors.lightBorder,
    textHi: AppColors.lightTextHi,
    textLo: AppColors.lightTextLo,
    primary: AppColors.gold,
    accent: AppColors.copper,
  );

  @override
  AppPalette copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceHi,
    Color? border,
    Color? textHi,
    Color? textLo,
    Color? primary,
    Color? accent,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceHi: surfaceHi ?? this.surfaceHi,
      border: border ?? this.border,
      textHi: textHi ?? this.textHi,
      textLo: textLo ?? this.textLo,
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHi: Color.lerp(surfaceHi, other.surfaceHi, t)!,
      border: Color.lerp(border, other.border, t)!,
      textHi: Color.lerp(textHi, other.textHi, t)!,
      textLo: Color.lerp(textLo, other.textLo, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

/// Sugar so any widget can read `context.palette`.
extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
