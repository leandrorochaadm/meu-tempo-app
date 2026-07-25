import 'package:injectable/injectable.dart';

import '../entities/task_entity.dart';
import '../entities/task_node.dart';
import '../services/overdue_evaluator.dart';
import 'get_prioritized_leaves_use_case.dart';

/// Constrói a floresta de [TaskNode] (raízes = tarefas mãe) a partir da lista
/// plana de tarefas. Cálculo que cruza dados → UseCase (não vive na UI).
@lazySingleton
class BuildTaskTreeUseCase {
  const BuildTaskTreeUseCase(this._getPrioritizedLeaves);

  final GetPrioritizedLeavesUseCase _getPrioritizedLeaves;

  /// Chamada síncrona (transformação pura em memória) — não faz I/O.
  /// `today` (opcional) marca as folhas atrasadas (prazo vencido, não
  /// concluídas) e resolve o `rank` de cada folha na fila de prioridade; quando
  /// ausente, nenhuma folha é marcada como atrasada nem recebe posição.
  List<TaskNode> call(List<TaskEntity> tasks, [DateTime? today]) {
    final childrenByParent = <String?, List<TaskEntity>>{};
    for (final task in tasks) {
      childrenByParent.putIfAbsent(task.parentId, () => []).add(task);
    }

    // A fila é resolvida uma única vez para a árvore toda — não por nó.
    final rankByTaskId = today == null
        ? const <String, int>{}
        : {
            for (final leaf in _getPrioritizedLeaves(tasks, today))
              leaf.task.id: leaf.rank,
          };

    List<TaskNode> build(String? parentId, int level) {
      final items = childrenByParent[parentId] ?? const [];
      return items
          .map((task) => TaskNode(
                task: task,
                level: level,
                children: build(task.id, level + 1),
                isOverdue:
                    today != null && OverdueEvaluator.isOverdue(task, today),
                rank: rankByTaskId[task.id],
              ))
          .toList();
    }

    return build(null, 0);
  }
}
