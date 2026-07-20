import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/utils/formatters/duration_formatter.dart';
import '../../domain/entities/task_node.dart';

/// Renderiza um nó da árvore (mãe/filha/neta) com indentação por nível.
/// Folha: mostra o tempo estimado. Mãe/avó: tempo derivado + barra de progresso.
class TaskNodeTile extends StatelessWidget {
  const TaskNodeTile({
    super.key,
    required this.node,
    required this.onAddSubtask,
  });

  final TaskNode node;

  /// Chamado ao tocar em "+ subtarefa" (só aparece se o nó aceita filhas).
  final void Function(TaskNode parent) onAddSubtask;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final task = node.task;
    final accent = colors.categoryAt(node.level);

    return Container(
      margin: EdgeInsets.only(left: context.space.xl * node.level),
      padding: EdgeInsets.symmetric(
        horizontal: context.space.lg,
        vertical: context.space.md,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: context.radius.lgRadius,
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                node.isLeaf
                    ? (task.isDone
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined)
                    : Icons.folder_rounded,
                color: node.isLeaf
                    ? (task.isDone ? colors.success : colors.textMuted)
                    : accent,
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
              SizedBox(width: context.space.sm),
              Text(
                DurationFormatter.hm(node.totalEstimatedMinutes),
                style: context.text.labelSmall,
              ),
              if (!node.isMaxLevel)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.add_rounded, color: colors.primary),
                  tooltip: 'Adicionar subtarefa',
                  onPressed: () => onAddSubtask(node),
                ),
            ],
          ),
          if (!node.isLeaf) ...[
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
    );
  }
}
