import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/utils/formatters/date_formatter.dart';
import '../../../../core/utils/formatters/duration_formatter.dart';
import '../../domain/entities/prioritized_leaf.dart';

/// Item da listagem por prioridade: título, subtítulo (mãe › avó), pontuação
/// e cronômetro em 1 toque.
class PrioritizedLeafTile extends StatelessWidget {
  const PrioritizedLeafTile({
    super.key,
    required this.leaf,
    required this.isActive,
    required this.onToggleTimer,
    required this.today,
  });

  final PrioritizedLeaf leaf;
  final bool isActive;
  final VoidCallback onToggleTimer;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final task = leaf.task;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.space.lg,
        vertical: context.space.md,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: context.radius.lgRadius,
        border: Border(
          left: BorderSide(
            color: isActive ? colors.timerActive : colors.primary,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leaf.ancestryLabel.isNotEmpty)
                  Text(
                    leaf.ancestryLabel,
                    style: context.text.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  task.title,
                  style: context.text.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: context.space.xs),
                Text(
                  '${DurationFormatter.hm(task.estimatedMinutes ?? 0)}'
                  ' · ${DateFormatter.relativeLabel(task.dueDate ?? today, today)}'
                  ' · prio ${leaf.priority}',
                  style: context.text.labelSmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onToggleTimer,
            tooltip: isActive ? 'Parar' : 'Iniciar',
            icon: Icon(
              isActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: isActive ? colors.timerActive : colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
