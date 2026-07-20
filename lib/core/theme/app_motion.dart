import 'package:flutter/material.dart';

/// Tokens de movimento (durações/curvas) — usados por `context.motion`.
@immutable
class AppMotion extends ThemeExtension<AppMotion> {
  const AppMotion({
    this.fast = const Duration(milliseconds: 150),
    this.medium = const Duration(milliseconds: 220),
    this.slow = const Duration(milliseconds: 320),
    this.curve = Curves.easeOutCubic,
  });

  final Duration fast;
  final Duration medium;
  final Duration slow;
  final Curve curve;

  static const AppMotion standard = AppMotion();

  @override
  AppMotion copyWith({
    Duration? fast,
    Duration? medium,
    Duration? slow,
    Curve? curve,
  }) =>
      AppMotion(
        fast: fast ?? this.fast,
        medium: medium ?? this.medium,
        slow: slow ?? this.slow,
        curve: curve ?? this.curve,
      );

  @override
  AppMotion lerp(ThemeExtension<AppMotion>? other, double t) => this;
}
