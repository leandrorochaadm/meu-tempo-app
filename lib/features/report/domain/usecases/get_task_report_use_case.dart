import 'package:injectable/injectable.dart';

import '../../../appointment/domain/entities/appointment_entity.dart';
import '../../../task/domain/entities/task_entity.dart';
import '../../../task/domain/entities/time_entry_entity.dart';
import '../../../task/domain/entities/timer_target_type_enum.dart';
import '../entities/report_tree_node.dart';
import '../entities/task_report_sort_enum.dart';

/// Monta o detalhe **hierárquico** do relatório de uma lista dentro de um
/// período: a árvore (avó → filha → neta) das tarefas que tiveram tempo, mais
/// os compromissos, com gasto (do período) × estimado + estouro. Toda a
/// agregação/ordenação vive aqui (domínio).
///
/// Semântica (espelha `GetListReportUseCase`, H7):
/// - **gasto** do nó = soma dos `TimeEntry` do período (folha = próprio;
///   mãe/avó = tempo próprio, se houver, + filhos); só entram nós com tempo;
/// - **estimado** = `estimatedMinutes` da folha; na mãe/avó, soma das folhas;
/// - **compromisso** entra como nó de topo, sem estimativa (nem estouro).
@lazySingleton
class GetTaskReportUseCase {
  const GetTaskReportUseCase();

  TaskReport call(
    List<TimeEntryEntity> entries,
    List<TaskEntity> tasks,
    List<AppointmentEntity> appointments,
    String listId,
    TaskReportSortEnum sort,
  ) {
    final byId = {for (final t in tasks) t.id: t};
    final apptById = {for (final a in appointments) a.id: a};

    // Minutos do período por alvo, apenas da lista pedida.
    final taskMinutes = <String, int>{};
    final apptMinutes = <String, int>{};
    for (final e in entries) {
      if (e.listId != listId) continue;
      if (e.targetType == TimerTargetTypeEnum.task) {
        taskMinutes[e.targetId] = (taskMinutes[e.targetId] ?? 0) + e.minutes;
      } else {
        apptMinutes[e.targetId] = (apptMinutes[e.targetId] ?? 0) + e.minutes;
      }
    }

    // Tarefas com tempo (existentes) + seus ancestrais compõem a árvore exibida.
    final relevant = <String>{};
    for (final id in taskMinutes.keys) {
      var cursor = byId[id];
      while (cursor != null && relevant.add(cursor.id)) {
        cursor = cursor.parentId == null ? null : byId[cursor.parentId];
      }
    }

    // Filhos relevantes por pai (dentro do conjunto relevante).
    final childrenOf = <String?, List<TaskEntity>>{};
    for (final id in relevant) {
      final t = byId[id]!;
      final parentKey = relevant.contains(t.parentId) ? t.parentId : null;
      childrenOf.putIfAbsent(parentKey, () => []).add(t);
    }

    ReportTreeNode buildNode(TaskEntity t, int level) {
      final kids = (childrenOf[t.id] ?? const <TaskEntity>[])
          .map((c) => buildNode(c, level + 1))
          .toList();
      kids.sort((a, b) => b.spentMinutes.compareTo(a.spentMinutes));
      final own = taskMinutes[t.id] ?? 0;
      final spent = kids.fold(own, (sum, k) => sum + k.spentMinutes);
      // Estimado: folha exibida = própria; nó com filhos = soma das folhas.
      final estimated = kids.isEmpty
          ? (t.estimatedMinutes ?? 0)
          : kids.fold(0, (sum, k) => sum + (k.estimatedMinutes ?? 0));
      return ReportTreeNode(
        id: t.id,
        title: t.title,
        targetType: TimerTargetTypeEnum.task,
        level: level,
        spentMinutes: spent,
        estimatedMinutes: estimated,
        children: kids,
      );
    }

    final nodes = <ReportTreeNode>[
      for (final t in childrenOf[null] ?? const <TaskEntity>[])
        buildNode(t, 0),
      // Compromissos: nós de topo, sem estimativa.
      for (final entry in apptMinutes.entries)
        ReportTreeNode(
          id: entry.key,
          title: apptById[entry.key]?.title ?? 'Compromisso',
          targetType: TimerTargetTypeEnum.appointment,
          level: 0,
          spentMinutes: entry.value,
        ),
    ];

    _sortTop(nodes, sort);

    final totalSpent = taskMinutes.values.fold<int>(0, (s, m) => s + m) +
        apptMinutes.values.fold<int>(0, (s, m) => s + m);
    // Estimado total = soma das estimativas das folhas (tarefas) com tempo.
    final totalEstimated = taskMinutes.keys
        .map((id) => byId[id])
        .where((t) => t != null && !t.hasChildren)
        .fold<int>(0, (s, t) => s + (t!.estimatedMinutes ?? 0));

    return TaskReport(
      nodes: nodes,
      totalSpentMinutes: totalSpent,
      totalEstimatedMinutes: totalEstimated,
    );
  }

  void _sortTop(List<ReportTreeNode> nodes, TaskReportSortEnum sort) {
    switch (sort) {
      case TaskReportSortEnum.spent:
        nodes.sort((a, b) => b.spentMinutes.compareTo(a.spentMinutes));
      case TaskReportSortEnum.overrun:
        nodes.sort((a, b) {
          final oa = a.overrunMinutes;
          final ob = b.overrunMinutes;
          if (oa == null && ob == null) {
            return b.spentMinutes.compareTo(a.spentMinutes);
          }
          if (oa == null) return 1;
          if (ob == null) return -1;
          final byOverrun = ob.compareTo(oa);
          return byOverrun != 0
              ? byOverrun
              : b.spentMinutes.compareTo(a.spentMinutes);
        });
    }
  }
}
