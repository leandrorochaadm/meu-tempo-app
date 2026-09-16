import 'package:injectable/injectable.dart';

import '../entities/prioritized_leaf.dart';
import '../entities/task_entity.dart';
import '../services/ancestry_label_builder.dart';
import '../services/overdue_evaluator.dart';
import '../services/priority_calculator.dart';

/// Monta a lista **plana das folhas não concluídas** ordenada por prioridade:
/// `faixaDeEsforço × (5 − importância) × urgênciaDoPrazo`. Depende de `today`
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

    // Com o esforço em faixas (peso 1–4), o `total` assume poucos valores
    // distintos e o empate é a regra, não a exceção: o desempate precisa ser
    // total e determinístico, senão a ordem muda entre recargas.
    scored.sort((a, b) {
      final byPriority = b.breakdown.total.compareTo(a.breakdown.total);
      if (byPriority != 0) return byPriority;

      // 1º: prazo mais próximo primeiro (sem prazo vai para o fim). Compara
      // `daysUntilDue`, que o domínio já normalizou para o dia — o `dueDate`
      // cru carrega a hora da criação rápida e desempataria por minuto.
      final da = a.breakdown.daysUntilDue;
      final db = b.breakdown.daysUntilDue;
      if (da != null && db != null) {
        final byDue = da.compareTo(db);
        if (byDue != 0) return byDue;
      } else if (da == null && db != null) {
        return 1;
      } else if (da != null && db == null) {
        return -1;
      }

      // 2º: dentro da mesma faixa de esforço, a estimativa maior primeiro —
      // preserva "mais longa vem antes" que a faixa arredondou.
      final byEstimate = b.breakdown.estimatedMinutes
          .compareTo(a.breakdown.estimatedMinutes);
      if (byEstimate != 0) return byEstimate;

      // 3º: mais antiga primeiro; `id` fecha para a ordem ser sempre a mesma.
      final byCreatedAt = a.task.createdAt.compareTo(b.task.createdAt);
      if (byCreatedAt != 0) return byCreatedAt;
      return a.task.id.compareTo(b.task.id);
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
