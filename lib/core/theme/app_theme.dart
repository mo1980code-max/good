import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Kid-friendly theme: rounded, soft, impossible to get lost in.
abstract final class AppTheme {
  /// Bundled offline font (see the fonts block in pubspec.yaml).
  /// If the font files are not shipped yet the app still runs and falls back
  /// to the platform font — no network call, ever.
  static const String fontFamily = 'Fredoka';

  /// Minimum touch target for a 3-year-old finger (GDD section 13).
  static const double minTouchTarget = 96;

  static ThemeData get light {
    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.lavender,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.bgTop,
      fontFamily: fontFamily,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textDeep,
        displayColor: AppColors.textDeep,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 6,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lavender,
          foregroundColor: AppColors.white,
          elevation: 4,
          shadowColor: AppColors.shadow,
          minimumSize: const Size(minTouchTarget, 64),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textDeep, size: 32),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll<Color>(AppColors.white),
        trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          return states.contains(WidgetState.selected)
              ? AppColors.mint
              : AppColors.locked;
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
      ),
    );
  }
}
