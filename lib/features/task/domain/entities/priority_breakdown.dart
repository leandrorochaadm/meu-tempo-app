import 'package:equatable/equatable.dart';

import 'importance_enum.dart';

/// Detalhamento do cálculo da prioridade de uma folha, com cada fator já
/// resolvido — a UI só exibe, nunca recalcula (ver `architecture.md`).
///
/// Fórmula: `tempoEstimado × (5 − importância) × urgênciaDoPrazo`.
class PriorityBreakdown extends Equatable {
  const PriorityBreakdown({
    required this.estimatedMinutes,
    required this.importance,
    required this.urgencyWeight,
    required this.daysUntilDue,
  });

  final int estimatedMinutes;
  final ImportanceEnum importance;

  /// Peso da urgência já aplicado (faixa do prazo ou `6 + dias de atraso`).
  final int urgencyWeight;

  /// Dias até o prazo — negativo = atrasada, `null` = sem prazo.
  final int? daysUntilDue;

  /// Multiplicador da importância: `5 − valor` (importância 1 = fator 4).
  int get importanceFactor => 5 - importance.value;

  /// Pontuação final de prioridade.
  int get total => estimatedMinutes * importanceFactor * urgencyWeight;

  /// Dias de atraso (0 quando no prazo ou sem prazo).
  int get overdueDays {
    final days = daysUntilDue;
    return days != null && days < 0 ? -days : 0;
  }

  bool get isOverdue => overdueDays > 0;

  /// Vence exatamente hoje.
  bool get isDueToday => daysUntilDue == 0;

  @override
  List<Object?> get props =>
      [estimatedMinutes, importance, urgencyWeight, daysUntilDue];
}
