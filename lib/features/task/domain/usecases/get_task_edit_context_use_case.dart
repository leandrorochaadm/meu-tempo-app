import 'package:injectable/injectable.dart';

import '../entities/parent_candidate_entity.dart';
import '../entities/task_edit_context.dart';
import '../entities/task_entity.dart';
import '../entities/task_node.dart';
import '../services/ancestry_label_builder.dart';
import 'build_task_tree_use_case.dart';

/// Resolve o [TaskEditContext] de uma tarefa a partir da lista plana: monta a
/// árvore, calcula os candidatos válidos a mãe (exclui a própria, seus
/// descendentes e as netas — evita ciclo e respeita o limite de 3 níveis) e o
/// breadcrumb da mãe atual. Transformação pura em memória (sem I/O) — por isso
/// é síncrona, como [BuildTaskTreeUseCase]/[GetPrioritizedLeavesUseCase].
///
/// A regra "quem pode ser mãe" vive aqui, no domínio, e serve tanto ao editar
/// quanto ao mover — sem duplicar cálculo na `presentation`.
@lazySingleton
class GetTaskEditContextUseCase {
  const GetTaskEditContextUseCase(this._buildTree);

  final BuildTaskTreeUseCase _buildTree;

  /// Retorna `null` se a tarefa não estiver na lista (não encontrada).
  TaskEditContext? call(String taskId, List<TaskEntity> tasks) {
    final byId = {for (final t in tasks) t.id: t};
    final task = byId[taskId];
    if (task == null) return null;

    final roots = _buildTree(tasks);
    final excluded = _excludedFor(taskId, roots);
    final candidates = _candidates(roots, excluded);

    return TaskEditContext(
      task: task,
      parentCandidates: candidates,
      currentParentLabel: AncestryLabelBuilder.of(task, byId),
    );
  }

  /// A própria tarefa e todos os seus descendentes (uma tarefa não pode virar
  /// filha de si mesma nem de uma neta sua).
  Set<String> _excludedFor(String taskId, List<TaskNode> roots) {
    final excluded = <String>{};
    void collect(TaskNode n) {
      excluded.add(n.task.id);
      n.children.forEach(collect);
    }

    TaskNode? find(List<TaskNode> nodes) {
      for (final n in nodes) {
        if (n.task.id == taskId) return n;
        final hit = find(n.children);
        if (hit != null) return hit;
      }
      return null;
    }

    final node = find(roots);
    if (node != null) {
      collect(node);
    } else {
      excluded.add(taskId);
    }
    return excluded;
  }

  /// Candidatos válidos, cada um com o nível e os títulos dos ancestrais para a
  /// UI montar o breadcrump. Nós excluídos e netas (nível máximo) ficam de fora.
  List<ParentCandidateEntity> _candidates(
    List<TaskNode> roots,
    Set<String> excluded,
  ) {
    final out = <ParentCandidateEntity>[];
    void visit(TaskNode n, List<String> ancestors) {
      if (!excluded.contains(n.task.id) && !n.isMaxLevel) {
        out.add(ParentCandidateEntity(
          id: n.task.id,
          title: n.task.title,
          level: n.level,
          ancestorTitles: ancestors,
        ));
      }
      for (final c in n.children) {
        visit(c, [...ancestors, n.task.title]);
      }
    }

    for (final r in roots) {
      visit(r, const []);
    }
    return out;
  }
}
