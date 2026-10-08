import 'package:flutter/material.dart';

import '../theme/theme_context_extensions.dart';

/// Notice banner at the top of the screen (below the app bar), with a main
/// action and a dismiss button. Unlike the snackbar, it does not go away by
/// itself: it stays until the user acts or the app removes it. Shown by the
/// [ScaffoldMessenger], so it follows navigation between screens.
abstract final class AppNoticeBanner {
  /// Replaces the current banner with one showing [message].
  static void show(
    BuildContext context, {
    required IconData icon,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    required VoidCallback onDismiss,
    String dismissLabel = 'Agora não',
  }) {
    final colors = context.colors;
    ScaffoldMessenger.of(context)
      ..removeCurrentMaterialBanner()
      ..showMaterialBanner(
        MaterialBanner(
          backgroundColor: colors.surfaceHigh,
          dividerColor: colors.border,
          leading: Icon(icon, color: colors.warning),
          content: Text(
            message,
            style: context.text.bodyMedium?.copyWith(color: colors.textPrimary),
          ),
          actions: [
            TextButton(onPressed: onDismiss, child: Text(dismissLabel)),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      );
  }

  /// Removes the current banner (animated).
  static void hide(BuildContext context) =>
      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
}
