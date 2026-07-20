import 'package:flutter/material.dart';

import '../theme/theme_context_extensions.dart';

/// Tela vazia que **ensina o próximo passo** (H13) — nunca fica em branco.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.space.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(context.space.xl),
              decoration: BoxDecoration(
                color: colors.surfaceHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: colors.primary),
            ),
            SizedBox(height: context.space.xl),
            Text(title, style: context.text.titleMedium),
            SizedBox(height: context.space.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
