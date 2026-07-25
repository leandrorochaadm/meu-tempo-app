import 'package:injectable/injectable.dart';

import '../../../list/domain/entities/task_list_entity.dart';
import '../entities/active_task_details.dart';
import '../entities/task_entity.dart';
import '../services/overdue_evaluator.dart';
import '../services/priority_calculator.dart';
import 'get_prioritized_leaves_use_case.dart';

/// Resolve os metadados da folha em contagem para a barra do cronômetro: nome e
/// posição da lista, pontuação de prioridade, posição na fila e atraso do prazo.
///
/// Transformação pura em memória (sem I/O) — síncrona, como
/// [GetTaskEditContextUseCase]. Existe para a `presentation` receber o dado
/// pronto e não cruzar tarefa × listas × data de hoje na tela.
@lazySingleton
class GetActiveTaskDetailsUseCase {
  const GetActiveTaskDetailsUseCase(this._getPrioritizedLeaves);

  final GetPrioritizedLeavesUseCase _getPrioritizedLeaves;

  /// [allTasks] é a coleção completa do usuário — necessária para saber a
  /// **posição** da folha ativa na fila de prioridade (sem filtro de lista, para
  /// a barra refletir a fila global e não a visão filtrada da tela).
  ActiveTaskDetails call(
    TaskEntity task,
    List<TaskListEntity> lists,
    List<TaskEntity> allTasks,
    DateTime today,
  ) {
    final index = lists.indexWhere((l) => l.id == task.listId);
    return ActiveTaskDetails(
      listName: index == -1 ? '' : lists[index].name,
      listColorIndex: index == -1 ? 0 : index,
      breakdown: PriorityCalculator.breakdownOf(task, today),
      rank: _rankOf(task, allTasks, today),
      isOverdue: OverdueEvaluator.isOverdue(task, today),
    );
  }

  /// Posição na fila de prioridade, ou `null` quando a tarefa não entra nela
  /// (concluída, ou virou mãe enquanto o cronômetro rodava).
  int? _rankOf(TaskEntity task, List<TaskEntity> allTasks, DateTime today) {
    for (final leaf in _getPrioritizedLeaves(allTasks, today)) {
      if (leaf.task.id == task.id) return leaf.rank;
    }
    return null;
  }
}
