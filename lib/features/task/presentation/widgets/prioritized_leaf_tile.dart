import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/swipe_action_tile.dart';
import '../../../../core/ui/task_crud_menu.dart';
import '../../../../core/ui/task_running_badge.dart';
import '../../../../core/ui/timer_toggle_button.dart';
import '../../../../core/utils/formatters/date_formatter.dart';
import '../../../../core/utils/formatters/duration_formatter.dart';
import '../../domain/entities/prioritized_leaf.dart';
import 'priority_info_button.dart';

/// Item da listagem por prioridade em 2 linhas: concluir, ancestralidade
/// (mãe › avó) e título, cronômetro ▶/■ em 1 toque e menu ⋮ (Editar · Mover ·
/// Somar 30 min · Excluir); abaixo, gasto · prazo · posição, tocável para ver
/// como a prioridade é calculada.
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
          horizontal: context.space.md,
          vertical: context.space.sm,
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: onToggleDone,
                  tooltip: task.isDone ? 'Reabrir' : 'Concluir',
                  icon: Icon(
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
                      Text(task.title, style: context.text.titleMedium),
                    ],
                  ),
                ),
                TimerToggleButton(isActive: isActive, onPressed: onToggleTimer),
                TaskCrudMenu(
                  onEdit: onEdit,
                  onMove: onMove,
                  onDelete: onDelete,
                  onAddTime: onAddTime,
                ),
              ],
            ),
            SizedBox(height: context.space.xs),
            Padding(
              padding: EdgeInsets.only(
                left: kMinInteractiveDimension + context.space.md,
              ),
              child: Row(
                children: [
                  if (isActive && activeStartedAt != null) ...[
                    TaskRunningBadge(startedAt: activeStartedAt!),
                    SizedBox(width: context.space.md),
                  ],
                  Expanded(
                    child: PriorityInfoButton(
                      breakdown: leaf.breakdown,
                      child: Text(
                        'gasto ${DurationFormatter.hm(task.spentMinutes)}'
                        ' · ${DateFormatter.relativeLabel(task.dueDate ?? today, today)}'
                        ' · #${leaf.rank}',
                        style: context.text.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
