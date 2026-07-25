import 'package:injectable/injectable.dart';

import '../entities/prioritized_leaf.dart';
import '../entities/task_entity.dart';
import '../services/ancestry_label_builder.dart';
import '../services/overdue_evaluator.dart';
import '../services/priority_calculator.dart';

/// Monta a lista **plana das folhas não concluídas** ordenada por prioridade:
/// `tempoEstimado × (5 − importância) × urgênciaDoPrazo`. Depende de `today`
/// (recebido como parâmetro), por isso vive no UseCase — não na Entity.
@lazySingleton
class GetPrioritizedLeavesUseCase {
  const GetPrioritizedLeavesUseCase();

  List<PrioritizedLeaf> call(List<TaskEntity> tasks, DateTime today) {
    final byId = {for (final t in tasks) t.id: t};
    final t0 = DateTime(today.year, today.month, today.day);

    final leaves = tasks
        .where((t) => !t.hasChildren && !t.isDone)
        .map((task) => PrioritizedLeaf(
              task: task,
              priority: PriorityCalculator.of(task, t0),
              ancestryLabel: AncestryLabelBuilder.of(task, byId),
              isOverdue: OverdueEvaluator.isOverdue(task, t0),
            ))
        .toList();

    leaves.sort((a, b) {
      final byPriority = b.priority.compareTo(a.priority);
      if (byPriority != 0) return byPriority;
      // Desempate: prazo mais próximo primeiro.
      final da = a.task.dueDate;
      final db = b.task.dueDate;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });

    return leaves;
  }
}
