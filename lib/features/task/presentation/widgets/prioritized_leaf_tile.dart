import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/swipe_action_tile.dart';
import '../../../../core/ui/task_crud_menu.dart';
import '../../../../core/ui/task_running_badge.dart';
import '../../../../core/ui/task_timer_actions.dart';
import '../../../../core/utils/formatters/date_formatter.dart';
import '../../../../core/utils/formatters/duration_formatter.dart';
import '../../domain/entities/prioritized_leaf.dart';

/// Item da listagem por prioridade: título, subtítulo (mãe › avó), tempo
/// gasto/estimado, pontuação, cronômetro em 1 toque e menu de CRUD.
class PrioritizedLeafTile extends StatelessWidget {
  const PrioritizedLeafTile({
    super.key,
    required this.leaf,
    required this.isActive,
    this.activeStartedAt,
    required this.onToggleTimer,
    required this.onAddTime,
    required this.onToggleDone,
    required this.onEdit,
    required this.onMove,
    required this.onDelete,
    required this.today,
  });

  final PrioritizedLeaf leaf;
  final bool isActive;

  /// Início da sessão do cronômetro quando esta folha está ativa (`null` caso
  /// não esteja) — alimenta o contador ao vivo hh:mm:ss do selo.
  final DateTime? activeStartedAt;
  final VoidCallback onToggleTimer;
  final VoidCallback onAddTime;
  final VoidCallback onToggleDone;
  final VoidCallback onEdit;
  final VoidCallback onMove;
  final VoidCallback onDelete;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final task = leaf.task;

    return SwipeActionTile(
      itemKey: ValueKey(task.id),
      onSwipeComplete: onToggleDone, // folha sempre conclui (toggle)
      onSwipeEdit: onEdit,
      onLongPressDelete: onDelete,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.space.lg,
          vertical: context.space.md,
        ),
        decoration: BoxDecoration(
          color: isActive ? colors.timerActiveSurface : colors.surface,
          borderRadius: context.radius.lgRadius,
          border: Border(
            left: BorderSide(
              color: isActive
                  ? colors.timerActive
                  : leaf.isOverdue
                      ? colors.warning
                      : colors.primary,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: onToggleDone,
                  customBorder: const CircleBorder(),
                  child: Icon(
                    task.isDone
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: task.isDone ? colors.success : colors.textMuted,
                    size: 22,
                  ),
                ),
                SizedBox(width: context.space.md),
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
                    ],
                  ),
                ),
                TaskCrudMenu(
                  onEdit: onEdit,
                  onMove: onMove,
                  onDelete: onDelete,
                ),
              ],
            ),
            SizedBox(height: context.space.xs),
            Row(
              children: [
                if (isActive && activeStartedAt != null) ...[
                  TaskRunningBadge(startedAt: activeStartedAt!),
                  SizedBox(width: context.space.md),
                ],
                Expanded(
                  child: Text(
                    'gasto ${DurationFormatter.hm(task.spentMinutes)}'
                    ' · est. ${DurationFormatter.hm(task.estimatedMinutes ?? 0)}'
                    ' · ${DateFormatter.relativeLabel(task.dueDate ?? today, today)}'
                    ' · prio ${leaf.priority}',
                    style: context.text.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.space.sm),
            TaskTimerActions(
              isActive: isActive,
              onToggleTimer: onToggleTimer,
              onAddTime: onAddTime,
            ),
          ],
        ),
      ),
    );
  }
}
