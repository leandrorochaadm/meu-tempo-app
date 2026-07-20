import 'package:flutter/material.dart';

/// Tipografia do app (ver `.claude/rules/design.md`).
///
/// Família **Manrope** empacotada como asset (proibido `google_fonts`). Enquanto
/// o asset não é adicionado, o Flutter recai na fonte do sistema — a hierarquia
/// de tamanhos/pesos é mantida.
class AppTypography {
  const AppTypography._();

  static const String fontFamily = 'Manrope';

  /// Dígitos tabulares para tempo/cronômetro (dígitos alinhados).
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static TextTheme textTheme(Color primary, Color secondary) => TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: primary,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: primary,
        ),
        titleMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: primary,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: primary,
        ),
        bodySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: secondary,
        ),
        labelLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        labelSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: secondary,
        ),
      );
}
