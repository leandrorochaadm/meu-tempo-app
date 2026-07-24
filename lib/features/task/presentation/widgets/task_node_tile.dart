import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/swipe_action_tile.dart';
import '../../../../core/ui/task_crud_menu.dart';
import '../../../../core/ui/task_running_badge.dart';
import '../../../../core/ui/task_timer_actions.dart';
import '../../../../core/utils/formatters/duration_formatter.dart';
import '../../domain/entities/task_node.dart';

/// Renderiza um nó da árvore (mãe/filha/neta) com indentação por nível.
/// Folha: tempo estimado/real + cronômetro e +30min. Mãe/avó: derivado + progresso.
class TaskNodeTile extends StatelessWidget {
  const TaskNodeTile({
    super.key,
    required this.node,
    required this.isActive,
    this.activeStartedAt,
    required this.onAddSubtask,
    required this.onToggleTimer,
    required this.onAddTime,
    required this.onToggleDone,
    required this.onDelete,
    required this.onEdit,
    required this.onMove,
  });

  final TaskNode node;
  final bool isActive;

  /// Início da sessão do cronômetro quando este nó está ativo (`null` caso não
  /// esteja) — alimenta o contador ao vivo hh:mm:ss do selo.
  final DateTime? activeStartedAt;
  final void Function(TaskNode parent) onAddSubtask;
  final void Function(TaskNode node, bool start) onToggleTimer;
  final void Function(TaskNode node, int minutes) onAddTime;
  final void Function(TaskNode node, bool done) onToggleDone;
  final void Function(TaskNode node) onDelete;
  final void Function(TaskNode node) onEdit;
  final void Function(TaskNode node) onMove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final task = node.task;
    final accent = colors.categoryAt(node.level);

    return SwipeActionTile(
      itemKey: ValueKey(task.id),
      // Só folha conclui; mãe/avó não têm conclusão (swipe-direita desabilitado).
      onSwipeComplete: node.isLeaf
          ? () => onToggleDone(node, !task.isDone)
          : null,
      onSwipeEdit: () => onEdit(node),
      onLongPressDelete: () => onDelete(node),
      child: Container(
        margin: EdgeInsets.only(left: context.space.xl * node.level),
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
                  : node.isOverdue
                      ? colors.warning
                      : accent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (node.isLeaf)
                  InkWell(
                    onTap: () => onToggleDone(node, !task.isDone),
                    customBorder: const CircleBorder(),
                    child: Icon(
                      task.isDone
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: task.isDone ? colors.success : colors.textMuted,
                      size: 22,
                    ),
                  )
                else
                  Icon(Icons.folder_rounded, color: accent, size: 22),
                SizedBox(width: context.space.md),
                Expanded(
                  child: Text(
                    task.title,
                    style: context.text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!node.isMaxLevel)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.add_rounded, color: colors.primary),
                    tooltip: 'Adicionar subtarefa',
                    onPressed: () => onAddSubtask(node),
                  ),
                TaskCrudMenu(
                  onEdit: () => onEdit(node),
                  onMove: () => onMove(node),
                  onDelete: () => onDelete(node),
                ),
              ],
            ),
            SizedBox(height: context.space.xs),
            _MetaRow(
              node: node,
              isActive: isActive,
              activeStartedAt: activeStartedAt,
            ),
            if (node.isLeaf) ...[
              SizedBox(height: context.space.sm),
              TaskTimerActions(
                isActive: isActive,
                onToggleTimer: () => onToggleTimer(node, !isActive),
                onAddTime: () => onAddTime(node, TaskTimerActions.quickMinutes),
              ),
            ] else ...[
              SizedBox(height: context.space.sm),
              ClipRRect(
                borderRadius: context.radius.pillRadius,
                child: LinearProgressIndicator(
                  value: node.progress,
                  minHeight: 6,
                  backgroundColor: colors.surfaceHigh,
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
              SizedBox(height: context.space.xs),
              Text(
                '${node.doneLeafCount}/${node.leafCount} concluídas',
                style: context.text.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.node,
    required this.isActive,
    required this.activeStartedAt,
  });

  final TaskNode node;
  final bool isActive;
  final DateTime? activeStartedAt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isActive && activeStartedAt != null) ...[
          TaskRunningBadge(startedAt: activeStartedAt!),
          SizedBox(width: context.space.md),
        ],
        Text(
          'gasto ${DurationFormatter.hm(node.totalSpentMinutes)}'
          ' · est. ${DurationFormatter.hm(node.totalEstimatedMinutes)}',
          style: context.text.labelSmall,
        ),
      ],
    );
  }
}
