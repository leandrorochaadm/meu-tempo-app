import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/utils/formatters/duration_formatter.dart';
import '../../domain/entities/task_entity.dart';

/// Card de uma tarefa na listagem.
class TaskCardWidget extends StatelessWidget {
  const TaskCardWidget({super.key, required this.task});

  final TaskEntity task;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.space.lg,
        vertical: context.space.md,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: context.radius.lgRadius,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(
            task.isDone
                ? Icons.check_circle_rounded
                : Icons.circle_outlined,
            color: task.isDone ? colors.success : colors.textMuted,
            size: 22,
          ),
          SizedBox(width: context.space.md),
          Expanded(
            child: Text(
              task.title,
              style: context.text.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (task.estimatedMinutes != null) ...[
            SizedBox(width: context.space.sm),
            Text(
              DurationFormatter.hm(task.estimatedMinutes!),
              style: context.text.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}
