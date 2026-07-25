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

    // Pontua primeiro, ordena, e só então numera: o `rank` é a posição final na
    // lista ordenada, resolvido aqui para a UI não precisar calcular índice.
    final scored = tasks
        .where((t) => !t.hasChildren && !t.isDone)
        .map((task) => (
              task: task,
              breakdown: PriorityCalculator.breakdownOf(task, t0),
            ))
        .toList();

    scored.sort((a, b) {
      final byPriority = b.breakdown.total.compareTo(a.breakdown.total);
      if (byPriority != 0) return byPriority;
      // Desempate: prazo mais próximo primeiro.
      final da = a.task.dueDate;
      final db = b.task.dueDate;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });

    return [
      for (var i = 0; i < scored.length; i++)
        PrioritizedLeaf(
          task: scored[i].task,
          breakdown: scored[i].breakdown,
          ancestryLabel: AncestryLabelBuilder.of(scored[i].task, byId),
          rank: i + 1,
          isOverdue: OverdueEvaluator.isOverdue(scored[i].task, t0),
        ),
    ];
  }
}
