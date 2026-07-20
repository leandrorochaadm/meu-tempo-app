import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/utils/formatters/duration_formatter.dart';
import '../../domain/entities/task_node.dart';

/// Renderiza um nó da árvore (mãe/filha/neta) com indentação por nível.
/// Folha: tempo estimado/real + cronômetro e +30min. Mãe/avó: derivado + progresso.
class TaskNodeTile extends StatelessWidget {
  const TaskNodeTile({
    super.key,
    required this.node,
    required this.isActive,
    required this.onAddSubtask,
    required this.onToggleTimer,
    required this.onAddTime,
    required this.onToggleDone,
    required this.onDelete,
  });

  final TaskNode node;
  final bool isActive;
  final void Function(TaskNode parent) onAddSubtask;
  final void Function(TaskNode node, bool start) onToggleTimer;
  final void Function(TaskNode node, int minutes) onAddTime;
  final void Function(TaskNode node, bool done) onToggleDone;
  final void Function(TaskNode node) onDelete;

  static const int _quickMinutes = 30;

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
        border: Border(
          left: BorderSide(
            color: isActive ? colors.timerActive : accent,
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
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: colors.textMuted),
                onSelected: (v) {
                  if (v == 'delete') onDelete(node);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'delete', child: Text('Excluir')),
                ],
              ),
            ],
          ),
          SizedBox(height: context.space.xs),
          _MetaRow(node: node, isActive: isActive),
          if (node.isLeaf) ...[
            SizedBox(height: context.space.sm),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => onToggleTimer(node, !isActive),
                  icon: Icon(
                    isActive
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  label: Text(isActive ? 'Parar' : 'Iniciar'),
                ),
                SizedBox(width: context.space.sm),
                OutlinedButton(
                  onPressed: () => onAddTime(node, _quickMinutes),
                  child: const Text('+30 min'),
                ),
              ],
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
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.node, required this.isActive});

  final TaskNode node;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        if (isActive) ...[
          Icon(Icons.timelapse_rounded, size: 14, color: colors.timerActive),
          SizedBox(width: context.space.xs),
          Text('rodando', style: context.text.labelSmall),
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
