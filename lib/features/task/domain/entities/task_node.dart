import 'package:equatable/equatable.dart';

import 'task_entity.dart';

/// Nó da árvore de tarefas (mãe → filha → neta). Objeto de domínio puro cujas
/// regras de agregação são **getters intrínsecos** — a UI só exibe, nunca soma.
///
/// `level`: 0 = mãe, 1 = filha, 2 = neta (profundidade calculada na construção).
class TaskNode extends Equatable {
  const TaskNode({
    required this.task,
    required this.level,
    this.children = const [],
    this.isOverdue = false,
  });

  final TaskEntity task;
  final int level;
  final List<TaskNode> children;

  /// Folha com prazo vencido e não concluída — sinaliza atraso na UI.
  final bool isOverdue;

  bool get isLeaf => children.isEmpty;

  /// Máximo de níveis atingido (neta não aceita filhas).
  bool get isMaxLevel => level >= 2;

  /// Tempo estimado: na folha, o próprio; na mãe/avó, a soma das folhas.
  int get totalEstimatedMinutes {
    if (isLeaf) return task.estimatedMinutes ?? 0;
    return children.fold(0, (sum, c) => sum + c.totalEstimatedMinutes);
  }

  /// Tempo real (cronômetro + manual): na folha, o próprio; acima, a soma.
  int get totalSpentMinutes {
    if (isLeaf) return task.spentMinutes;
    return children.fold(0, (sum, c) => sum + c.totalSpentMinutes);
  }

  /// Número de folhas sob este nó (a própria, se for folha).
  int get leafCount {
    if (isLeaf) return 1;
    return children.fold(0, (sum, c) => sum + c.leafCount);
  }

  /// Folhas concluídas sob este nó.
  int get doneLeafCount {
    if (isLeaf) return task.isDone ? 1 : 0;
    return children.fold(0, (sum, c) => sum + c.doneLeafCount);
  }

  /// Progresso (0.0–1.0) = proporção de folhas concluídas.
  double get progress {
    final total = leafCount;
    if (total == 0) return 0;
    return doneLeafCount / total;
  }

  @override
  List<Object?> get props => [task, level, children, isOverdue];
}
