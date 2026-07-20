import 'package:flutter/material.dart';

import '../theme/theme_context_extensions.dart';

/// Esqueleto de lista exibido no carregamento (no lugar de um spinner).
class AppListSkeleton extends StatelessWidget {
  const AppListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(context.space.lg),
      itemCount: itemCount,
      separatorBuilder: (_, _) => SizedBox(height: context.space.md),
      itemBuilder: (_, _) => _SkeletonTile(),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: context.radius.lgRadius,
      ),
    );
  }
}
