import 'package:flutter/material.dart';

import '../../../../core/constants/app_defaults.dart';
import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/swipe_action_tile.dart';
import '../../../../core/ui/task_crud_menu.dart';
import '../../../../core/ui/task_running_badge.dart';
import '../../../../core/ui/timer_toggle_button.dart';
import '../../../../core/utils/formatters/duration_formatter.dart';
import '../../domain/entities/task_node.dart';

/// Renderiza um nó da árvore (mãe/filha/neta) com indentação por nível, em 2
/// linhas. Folha: concluir, título, cronômetro ▶/■ em 1 toque e menu ⋮ (Editar ·
/// Mover · Adicionar subtarefa · Somar 30 min · Excluir); abaixo, gasto e
/// posição. Mãe/avó: pasta, título, "+" para criar filha e ⋮; abaixo, gasto
/// derivado, folhas concluídas e barra de progresso.
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
                  : node.isOverdue
                  ? colors.warning
                  : accent,
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
                if (node.isLeaf)
                  // Concluir/reabrir a folha (req. 10): botão de 48 dp com dica,
                  // para o toque no círculo verde ser visível como "Reabrir".
                  IconButton(
                    onPressed: () => onToggleDone(node, !task.isDone),
                    tooltip: task.isDone ? 'Reabrir' : 'Concluir',
                    icon: Icon(
                      task.isDone
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: task.isDone ? colors.success : colors.textMuted,
                      size: 22,
                    ),
                  )
                else
                  SizedBox.square(
                    dimension: kMinInteractiveDimension,
                    child: Center(
                      child: Icon(
                        Icons.folder_rounded,
                        color: accent,
                        size: 22,
                      ),
                    ),
                  ),
                SizedBox(width: context.space.md),
                Expanded(
                  child: Text(task.title, style: context.text.titleMedium),
                ),
                if (!node.isLeaf && !node.isMaxLevel)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.add_rounded, color: colors.primary),
                    tooltip: 'Adicionar subtarefa',
                    onPressed: () => onAddSubtask(node),
                  ),
                if (node.isLeaf)
                  TimerToggleButton(
                    isActive: isActive,
                    onPressed: () => onToggleTimer(node, !isActive),
                  ),
                TaskCrudMenu(
                  onEdit: () => onEdit(node),
                  onMove: () => onMove(node),
                  onDelete: () => onDelete(node),
                  onAddSubtask: node.isLeaf && !node.isMaxLevel
                      ? () => onAddSubtask(node)
                      : null,
                  onAddTime: node.isLeaf
                      ? () => onAddTime(node, AppDefaults.quickAddTimeMinutes)
                      : null,
                ),
              ],
            ),
            SizedBox(height: context.space.xs),
            Padding(
              padding: EdgeInsets.only(
                left: kMinInteractiveDimension + context.space.md,
              ),
              child: _MetaRow(
                node: node,
                isActive: isActive,
                activeStartedAt: activeStartedAt,
              ),
            ),
            if (!node.isLeaf) ...[
              SizedBox(height: context.space.xs),
              Padding(
                padding: EdgeInsets.only(
                  left: kMinInteractiveDimension + context.space.md,
                ),
                child: ClipRRect(
                  borderRadius: context.radius.pillRadius,
                  child: LinearProgressIndicator(
                    value: node.progress,
                    minHeight: 4,
                    backgroundColor: colors.surfaceHigh,
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
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
        Expanded(
          child: Text(
            'gasto ${DurationFormatter.hm(node.totalSpentMinutes)}'
            '${node.rank == null ? '' : ' · #${node.rank}'}'
            '${node.isLeaf ? '' : ' · ${node.doneLeafCount}/${node.leafCount} concluídas'}',
            style: context.text.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
