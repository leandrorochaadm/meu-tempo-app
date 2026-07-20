import 'package:flutter/material.dart';

/// Tokens de raio de borda — usados por `context.radius`.
@immutable
class AppRadius extends ThemeExtension<AppRadius> {
  const AppRadius({
    this.sm = 10,
    this.md = 16,
    this.lg = 20,
    this.pill = 999,
  });

  final double sm;
  final double md;
  final double lg;
  final double pill;

  static const AppRadius standard = AppRadius();

  BorderRadius get smRadius => BorderRadius.circular(sm);
  BorderRadius get mdRadius => BorderRadius.circular(md);
  BorderRadius get lgRadius => BorderRadius.circular(lg);
  BorderRadius get pillRadius => BorderRadius.circular(pill);

  @override
  AppRadius copyWith({double? sm, double? md, double? lg, double? pill}) =>
      AppRadius(
        sm: sm ?? this.sm,
        md: md ?? this.md,
        lg: lg ?? this.lg,
        pill: pill ?? this.pill,
      );

  @override
  AppRadius lerp(ThemeExtension<AppRadius>? other, double t) => this;
}
