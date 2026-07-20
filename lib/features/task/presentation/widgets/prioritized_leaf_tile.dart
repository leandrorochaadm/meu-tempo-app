import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/utils/formatters/date_formatter.dart';
import '../../../../core/utils/formatters/duration_formatter.dart';
import '../../domain/entities/prioritized_leaf.dart';

/// Item da listagem por prioridade: título, subtítulo (mãe › avó), pontuação,
/// cronômetro em 1 toque e menu de ações (editar/concluir/excluir).
class PrioritizedLeafTile extends StatelessWidget {
  const PrioritizedLeafTile({
    super.key,
    required this.leaf,
    required this.isActive,
    required this.onToggleTimer,
    required this.onEdit,
    required this.onToggleDone,
    required this.onDelete,
    required this.today,
  });

  final PrioritizedLeaf leaf;
  final bool isActive;
  final VoidCallback onToggleTimer;
  final VoidCallback onEdit;
  final VoidCallback onToggleDone;
  final VoidCallback onDelete;
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
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: colors.textMuted),
            onSelected: (value) => switch (value) {
              'edit' => onEdit(),
              'done' => onToggleDone(),
              'delete' => onDelete(),
              _ => null,
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'done',
                child: Text(task.isDone ? 'Reabrir' : 'Concluir'),
              ),
              const PopupMenuItem(value: 'edit', child: Text('Editar')),
              const PopupMenuItem(value: 'delete', child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }
}
