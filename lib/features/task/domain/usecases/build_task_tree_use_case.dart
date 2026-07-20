import 'package:injectable/injectable.dart';

import '../entities/task_entity.dart';
import '../entities/task_node.dart';

/// Constrói a floresta de [TaskNode] (raízes = tarefas mãe) a partir da lista
/// plana de tarefas. Cálculo que cruza dados → UseCase (não vive na UI).
@lazySingleton
class BuildTaskTreeUseCase {
  const BuildTaskTreeUseCase();

  /// Chamada síncrona (transformação pura em memória) — não faz I/O.
  List<TaskNode> call(List<TaskEntity> tasks) {
    final childrenByParent = <String?, List<TaskEntity>>{};
    for (final task in tasks) {
      childrenByParent.putIfAbsent(task.parentId, () => []).add(task);
    }

    List<TaskNode> build(String? parentId, int level) {
      final items = childrenByParent[parentId] ?? const [];
      return items
          .map((task) => TaskNode(
                task: task,
                level: level,
                children: build(task.id, level + 1),
              ))
          .toList();
    }

    return build(null, 0);
  }
}
