import 'package:equatable/equatable.dart';

import 'priority_breakdown.dart';
import 'task_entity.dart';

/// Folha na listagem por prioridade, com a pontuação calculada e o subtítulo
/// da hierarquia (mãe › avó).
class PrioritizedLeaf extends Equatable {
  const PrioritizedLeaf({
    required this.task,
    required this.breakdown,
    required this.ancestryLabel,
    required this.rank,
    this.isOverdue = false,
  });

  final TaskEntity task;

  /// Posição na lista ordenada, começando em 1 — a ordem de execução sugerida.
  /// Vem resolvida do UseCase (que é quem ordena); a UI só exibe "#1".
  final int rank;

  /// Fatores do cálculo da prioridade, prontos para exibição.
  final PriorityBreakdown breakdown;

  /// Pontuação final — derivada do [breakdown], nunca recalculada na UI.
  int get priority => breakdown.total;

  /// Ex.: "Lançar app › Fazer telas" (vazio se a folha for raiz).
  final String ancestryLabel;

  /// Prazo vencido (antes de hoje) e ainda não concluída — sinaliza atraso na UI.
  final bool isOverdue;

  @override
  List<Object?> get props => [task, breakdown, ancestryLabel, rank, isOverdue];
}
