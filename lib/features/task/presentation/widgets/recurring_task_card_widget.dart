import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/utils/formatters/duration_formatter.dart';
import '../../domain/entities/recurring_task_entity.dart';
import 'importance_presentation.dart';
import 'recurring_task_presentation.dart';

/// Cartão de um modelo de tarefa recorrente: faixa na cor da importância,
/// resumo dos dias, tempo, importância, lista e o botão "Adicionar hoje".
class RecurringTaskCardWidget extends StatelessWidget {
  const RecurringTaskCardWidget({
    super.key,
    required this.template,
    required this.listName,
    required this.onTap,
    required this.onAddToday,
  });

  final RecurringTaskEntity template;

  /// Nulo se a lista sumiu (o cartão segue sem quebrar).
  final String? listName;

  /// Abre a edição.
  final VoidCallback onTap;
  final VoidCallback onAddToday;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final importanceColor = template.importance.colorOf(context);
    return Material(
      color: colors.surface,
      borderRadius: context.radius.lgRadius,
      child: InkWell(
        borderRadius: context.radius.lgRadius,
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: context.space.md,
            vertical: context.space.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: context.radius.lgRadius,
            border: Border(left: BorderSide(color: importanceColor, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                template.title,
                style: text.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Wrap(
                spacing: context.space.md,
                children: [
                  Text(
                    template.scheduleLabel,
                    style: text.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    DurationFormatter.hm(template.estimatedMinutes),
                    style: text.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    template.importance.label,
                    style: text.bodySmall?.copyWith(color: importanceColor),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      listName ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: colors.textMuted),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onAddToday,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Adicionar hoje'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
