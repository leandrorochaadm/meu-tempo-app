import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/utils/formatters/date_formatter.dart';
import '../../../../core/utils/formatters/duration_formatter.dart';
import '../../domain/entities/time_entry_entity.dart';
import '../../domain/entities/time_entry_origin_enum.dart';

/// Item de registro de tempo: duração em destaque + data e origem, com ações
/// editar/excluir. Toque no corpo edita; ícone de lixeira exclui.
class TimeEntryTile extends StatelessWidget {
  const TimeEntryTile({
    super.key,
    required this.entry,
    required this.today,
    required this.onEdit,
    required this.onDelete,
  });

  final TimeEntryEntity entry;
  final DateTime today;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final originLabel = switch (entry.origin) {
      TimeEntryOriginEnum.timer => 'Cronômetro',
      TimeEntryOriginEnum.manual => 'Manual',
    };
    return Material(
      color: colors.surface,
      borderRadius: context.radius.lgRadius,
      child: InkWell(
        onTap: onEdit,
        borderRadius: context.radius.lgRadius,
        child: Padding(
          padding: EdgeInsets.all(context.space.lg),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded, color: colors.timerActive, size: 20),
              SizedBox(width: context.space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DurationFormatter.hm(entry.minutes),
                      style: context.text.titleMedium,
                    ),
                    SizedBox(height: context.space.xs),
                    Text(
                      '${DateFormatter.relativeLabel(entry.occurredAt, today)}'
                      ' · $originLabel',
                      style: context.text.bodySmall
                          ?.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: colors.danger),
                tooltip: 'Excluir registro',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
