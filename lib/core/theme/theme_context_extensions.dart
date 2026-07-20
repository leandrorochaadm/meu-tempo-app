import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_motion.dart';
import 'app_radius.dart';
import 'app_spacing.dart';

/// Açúcar sintático para as telas lerem os tokens do tema pelo `context`.
///
/// Ex.: `context.colors.primary`, `context.space.lg`, `context.radius.lgRadius`.
/// **Proibida** formatação hard-coded na `presentation` — sempre via estes getters.
extension ThemeContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get text => Theme.of(this).textTheme;

  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  AppSpacing get space => Theme.of(this).extension<AppSpacing>()!;
  AppRadius get radius => Theme.of(this).extension<AppRadius>()!;
  AppMotion get motion => Theme.of(this).extension<AppMotion>()!;
}
