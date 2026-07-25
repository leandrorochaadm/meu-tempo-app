import 'package:injectable/injectable.dart';

import '../../../list/domain/entities/task_list_entity.dart';
import '../entities/active_task_details.dart';
import '../entities/task_entity.dart';
import '../services/overdue_evaluator.dart';
import '../services/priority_calculator.dart';

/// Resolve os metadados da folha em contagem para a barra do cronômetro: nome e
/// posição da lista, pontuação de prioridade e atraso do prazo.
///
/// Transformação pura em memória (sem I/O) — síncrona, como
/// [GetTaskEditContextUseCase]. Existe para a `presentation` receber o dado
/// pronto e não cruzar tarefa × listas × data de hoje na tela.
@lazySingleton
class GetActiveTaskDetailsUseCase {
  const GetActiveTaskDetailsUseCase();

  ActiveTaskDetails call(
    TaskEntity task,
    List<TaskListEntity> lists,
    DateTime today,
  ) {
    final index = lists.indexWhere((l) => l.id == task.listId);
    return ActiveTaskDetails(
      listName: index == -1 ? '' : lists[index].name,
      listColorIndex: index == -1 ? 0 : index,
      priority: PriorityCalculator.of(task, today),
      isOverdue: OverdueEvaluator.isOverdue(task, today),
    );
  }
}
