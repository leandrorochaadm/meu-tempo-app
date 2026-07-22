import 'package:injectable/injectable.dart';

import '../entities/task_entity.dart';

/// Filtra as tarefas por lista para a tela principal. Regra de negócio (cruza
/// dados) → UseCase, nunca `where` solto na `presentation`.
///
/// `listId == null` → "Todas as listas" (retorna tudo). Caso contrário, mantém
/// as tarefas da lista **e** seus ancestrais (mãe/avó), para a árvore não ficar
/// com nós órfãos e para preservar o contexto hierárquico. Ancestrais nunca são
/// folhas, então não poluem a visão por prioridade.
@lazySingleton
class FilterTasksByListUseCase {
  const FilterTasksByListUseCase();

  /// Transformação pura e síncrona (sem I/O).
  List<TaskEntity> call(List<TaskEntity> tasks, String? listId) {
    if (listId == null) return tasks;

    final byId = {for (final t in tasks) t.id: t};
    final keep = <String>{};

    // 1) tarefas da lista selecionada.
    for (final task in tasks) {
      if (task.listId == listId) keep.add(task.id);
    }

    // 2) retém a cadeia de ancestrais das mantidas (preserva a árvore).
    for (final task in tasks) {
      if (!keep.contains(task.id)) continue;
      var parentId = task.parentId;
      while (parentId != null && byId.containsKey(parentId)) {
        if (!keep.add(parentId)) break; // ancestral já visitado.
        parentId = byId[parentId]!.parentId;
      }
    }

    return tasks.where((task) => keep.contains(task.id)).toList();
  }
}
