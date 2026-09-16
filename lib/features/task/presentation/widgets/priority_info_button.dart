import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/utils/formatters/duration_formatter.dart';
import '../../domain/entities/priority_breakdown.dart';
import 'effort_band_presentation.dart';
import 'importance_presentation.dart';

/// Ícone de "info" que abre a explicação do cálculo da prioridade.
///
/// Só exibe o que o [PriorityBreakdown] já traz resolvido do domínio — nenhuma
/// conta acontece aqui (ver `architecture.md`).
class PriorityInfoButton extends StatelessWidget {
  const PriorityInfoButton({super.key, required this.breakdown});

  final PriorityBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.info_outline_rounded),
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      color: context.colors.textMuted,
      tooltip: 'Como a prioridade é calculada',
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => _PriorityBreakdownDialog(breakdown: breakdown),
      ),
    );
  }
}

class _PriorityBreakdownDialog extends StatelessWidget {
  const _PriorityBreakdownDialog({required this.breakdown});

  final PriorityBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AlertDialog(
      title: const Text('Como calculamos'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FactorRow(
            label: 'Tempo estimado',
            value: DurationFormatter.hm(breakdown.estimatedMinutes),
          ),
          _FactorRow(
            label: 'Esforço',
            value: '${breakdown.effortBand.label}'
                ' (${breakdown.effortBand.weight})',
          ),
          _FactorRow(
            label: 'Importância',
            value: '${breakdown.importance.label}'
                ' (5 − ${breakdown.importance.value}'
                ' = ${breakdown.importanceFactor})',
            valueColor: breakdown.importance.colorOf(context),
          ),
          _FactorRow(
            label: 'Urgência',
            value: '${breakdown.urgencyWeight} (${_deadlineReason(breakdown)})',
            valueColor: breakdown.isOverdue ? colors.warning : null,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.space.md),
            child: Divider(height: 1, color: colors.border),
          ),
          Text(
            '${breakdown.effortBand.weight}'
            ' × ${breakdown.importanceFactor}'
            ' × ${breakdown.urgencyWeight}'
            ' = ${breakdown.total}',
            style: context.text.titleMedium,
          ),
          SizedBox(height: context.space.md),
          Text(
            'Tarefas mais longas, mais importantes e com prazo mais apertado '
            'pontuam mais alto e sobem na lista. O tempo entra pela faixa de '
            'esforço (rápida a longa), para não pesar mais que prazo e '
            'importância. Em atraso, a urgência sobe 1 por dia — quanto mais '
            'atrasada, maior a prioridade.',
            style: context.text.labelSmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendi'),
        ),
      ],
    );
  }

  /// Motivo do peso de urgência em PT — tradução de exibição do que o domínio
  /// já decidiu (dias até o prazo), sem recalcular faixa.
  static String _deadlineReason(PriorityBreakdown breakdown) {
    final days = breakdown.daysUntilDue;
    if (days == null) return 'sem prazo';
    if (breakdown.isOverdue) {
      final d = breakdown.overdueDays;
      return d == 1 ? 'atrasada 1 dia' : 'atrasada $d dias';
    }
    if (breakdown.isDueToday) return 'vence hoje';
    return days == 1 ? 'vence amanhã' : 'vence em $days dias';
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.space.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: context.text.labelSmall)),
          SizedBox(width: context.space.md),
          Flexible(
            child: Text(
              value,
              style: context.text.bodyMedium?.copyWith(color: valueColor),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
