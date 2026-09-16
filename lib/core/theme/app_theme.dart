import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_icons.dart';

/// Single source of truth for light + dark [ThemeData].
///
/// Fonts mirror MPC's brand:
///   display  -> Space Grotesk (MPC headings / wordmark)
///   body     -> Inter (covers Latin + Cyrillic)
///   mono     -> JetBrains Mono (addresses / figures)
/// Korean glyphs fall back to Gothic A1 via [fontFamilyFallback].
class AppTheme {
  const AppTheme._();

  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);
  static ThemeData light() => _build(AppPalette.light, Brightness.light);

  static String get displayFont => 'SpaceGrotesk';
  static String get monoFont => 'JetBrainsMono';

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    const cjkFallback = <String>['GothicA1'];

    final bodyTheme = _withFallback(
      base.textTheme.apply(
        fontFamily: 'Inter',
        bodyColor: p.textHi,
        displayColor: p.textHi,
      ),
      cjkFallback,
    );

    // Display styles use Space Grotesk while keeping the CJK fallback.
    final textTheme = bodyTheme.copyWith(
      displayLarge: bodyTheme.displayLarge?.copyWith(
        fontFamily: displayFont,
        fontFamilyFallback: cjkFallback,
      ),
      displayMedium: bodyTheme.displayMedium?.copyWith(
        fontFamily: displayFont,
        fontFamilyFallback: cjkFallback,
      ),
      displaySmall: bodyTheme.displaySmall?.copyWith(
        fontFamily: displayFont,
        fontFamilyFallback: cjkFallback,
      ),
      headlineMedium: bodyTheme.headlineMedium?.copyWith(
        fontFamily: displayFont,
        fontFamilyFallback: cjkFallback,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: p.primary,
        onPrimary: p.onPrimary,
        secondary: p.accent,
        onSecondary: Colors.white,
        surface: p.surface,
        onSurface: p.textHi,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      dividerColor: p.border,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontFamily: displayFont,
          fontWeight: FontWeight.w700,
          fontSize: 22,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: p.textHi),
      ),
      actionIconTheme: const ActionIconThemeData(
        backButtonIconBuilder: _buildBackIcon,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textHi,
          side: BorderSide(color: p.border),
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceHi,
        contentTextStyle: TextStyle(color: p.textHi),
        behavior: SnackBarBehavior.floating,
      ),
      extensions: <ThemeExtension<dynamic>>[p],
    );
  }

  static Widget _buildBackIcon(BuildContext context) {
    return const Icon(AppIcons.back, size: 20);
  }

  static TextTheme _withFallback(TextTheme t, List<String> fb) {
    TextStyle? f(TextStyle? s) => s?.copyWith(fontFamilyFallback: fb);
    return t.copyWith(
      displayLarge: f(t.displayLarge),
      displayMedium: f(t.displayMedium),
      displaySmall: f(t.displaySmall),
      headlineLarge: f(t.headlineLarge),
      headlineMedium: f(t.headlineMedium),
      headlineSmall: f(t.headlineSmall),
      titleLarge: f(t.titleLarge),
      titleMedium: f(t.titleMedium),
      titleSmall: f(t.titleSmall),
      bodyLarge: f(t.bodyLarge),
      bodyMedium: f(t.bodyMedium),
      bodySmall: f(t.bodySmall),
      labelLarge: f(t.labelLarge),
      labelMedium: f(t.labelMedium),
      labelSmall: f(t.labelSmall),
    );
  }
}
