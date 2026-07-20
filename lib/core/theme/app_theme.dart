import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_motion.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Monta o [ThemeData] escuro-único a partir dos tokens.
class AppTheme {
  const AppTheme._();

  static ThemeData get dark {
    const colors = AppColors.dark;
    final textTheme =
        AppTypography.textTheme(colors.textPrimary, colors.textSecondary);

    final scheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      surface: colors.surface,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      error: colors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.bgBase,
      colorScheme: scheme,
      textTheme: textTheme,
      fontFamily: AppTypography.fontFamily,
      splashFactory: InkSparkle.splashFactory,
      extensions: const [
        AppColors.dark,
        AppSpacing.standard,
        AppRadius.standard,
        AppMotion.standard,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgBase,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
        foregroundColor: colors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.standard.lgRadius,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.surfaceHigh,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.standard.mdRadius,
        ),
      ),
    );
  }
}
