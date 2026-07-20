import 'package:flutter/material.dart';

/// Tokens de cor do tema escuro-único (ver `.claude/rules/design.md`).
///
/// Exposto na UI via [ThemeExtension] `AppColors` — as telas leem por
/// `context.colors`, nunca com `Color(0x…)` hard-coded.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bgBase,
    required this.surface,
    required this.surfaceHigh,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primary,
    required this.onPrimary,
    required this.timerActive,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.category,
  });

  final Color bgBase;
  final Color surface;
  final Color surfaceHigh;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color primary;
  final Color onPrimary;
  final Color timerActive;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  /// Paleta categórica — cor por lista/tag/série de gráfico.
  final List<Color> category;

  static const AppColors dark = AppColors(
    bgBase: Color(0xFF101216),
    surface: Color(0xFF181B21),
    surfaceHigh: Color(0xFF212530),
    border: Color(0xFF2A2F3A),
    textPrimary: Color(0xFFECEEF3),
    textSecondary: Color(0xFFA2A9B8),
    textMuted: Color(0xFF6B7280),
    primary: Color(0xFF7C8CF8),
    onPrimary: Color(0xFF0F1220),
    timerActive: Color(0xFF4FD1C5),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    info: Color(0xFF60A5FA),
    category: [
      Color(0xFF7C8CF8), // indigo
      Color(0xFF4FD1C5), // teal
      Color(0xFF5FD0A0), // green
      Color(0xFFF5B84E), // amber
      Color(0xFFFB7185), // coral
      Color(0xFFB98CF0), // violet
      Color(0xFF56C7E0), // sky
      Color(0xFFF472B6), // rose
    ],
  );

  /// Cor determinística de uma lista pela sua posição/hash (round-robin).
  Color categoryAt(int index) => category[index % category.length];

  @override
  AppColors copyWith({
    Color? bgBase,
    Color? surface,
    Color? surfaceHigh,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? primary,
    Color? onPrimary,
    Color? timerActive,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    List<Color>? category,
  }) {
    return AppColors(
      bgBase: bgBase ?? this.bgBase,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      timerActive: timerActive ?? this.timerActive,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      category: category ?? this.category,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bgBase: Color.lerp(bgBase, other.bgBase, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      timerActive: Color.lerp(timerActive, other.timerActive, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      category: category,
    );
  }
}
