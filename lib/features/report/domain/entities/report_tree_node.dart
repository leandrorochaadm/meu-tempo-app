import 'package:equatable/equatable.dart';

import '../../../task/domain/entities/timer_target_type_enum.dart';

/// Nó da árvore do detalhe do relatório: uma tarefa (mãe/filha/neta) ou um
/// compromisso que teve tempo no período. O `spentMinutes` é o **gasto do
/// período** já agregado (folha = próprio; mãe/avó = próprio + filhos); o
/// `estimatedMinutes` é derivado (folha = próprio; mãe/avó = soma das folhas).
/// Compromisso não tem estimativa (nem estouro).
class ReportTreeNode extends Equatable {
  ReportTreeNode({
    required this.id,
    required this.title,
    required this.targetType,
    required this.level,
    required this.spentMinutes,
    this.estimatedMinutes,
    List<ReportTreeNode> children = const [],
  }) : children = List.unmodifiable(children);

  final String id;
  final String title;
  final TimerTargetTypeEnum targetType;

  /// Profundidade relativa dentro do detalhe: 0 = raiz exibida (avó/mãe/folha
  /// de topo ou compromisso), 1 = filha, 2 = neta.
  final int level;

  final int spentMinutes;
  final int? estimatedMinutes;
  final List<ReportTreeNode> children;

  bool get isLeaf => children.isEmpty;

  /// Estouro (gasto − estimado); `null` quando não há estimativa.
  int? get overrunMinutes =>
      estimatedMinutes == null ? null : spentMinutes - estimatedMinutes!;

  @override
  List<Object?> get props =>
      [id, title, targetType, level, spentMinutes, estimatedMinutes, children];
}

/// Resultado do detalhe do relatório de uma lista: os nós de topo (árvore) já
/// ordenados e os totais **agregados no domínio** (a UI só exibe — nunca soma).
class TaskReport extends Equatable {
  TaskReport({
    required List<ReportTreeNode> nodes,
    required this.totalSpentMinutes,
    required this.totalEstimatedMinutes,
  }) : nodes = List.unmodifiable(nodes);

  /// Nós de topo (raízes exibidas + compromissos).
  final List<ReportTreeNode> nodes;
  final int totalSpentMinutes;

  /// Soma das estimativas das folhas (tarefas) com tempo no período.
  final int totalEstimatedMinutes;

  /// Fração (0..1) que o tempo gasto de [node] representa no total do período.
  /// `0` quando o total é zero (sem base de comparação).
  double shareRatio(ReportTreeNode node) =>
      totalSpentMinutes == 0 ? 0 : node.spentMinutes / totalSpentMinutes;

  /// Percentual (0..100) que o tempo gasto de [node] representa no total gasto do
  /// período. `null` quando o total é zero (sem base de comparação).
  double? sharePercent(ReportTreeNode node) =>
      totalSpentMinutes == 0 ? null : shareRatio(node) * 100;

  bool get isEmpty => nodes.isEmpty;

  @override
  List<Object?> get props => [nodes, totalSpentMinutes, totalEstimatedMinutes];
}
