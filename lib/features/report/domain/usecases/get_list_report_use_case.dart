import 'package:injectable/injectable.dart';

import '../../../list/domain/entities/task_list_entity.dart';
import '../../../task/domain/entities/task_entity.dart';
import '../../../task/domain/entities/time_entry_entity.dart';
import '../../../task/domain/entities/timer_target_type_enum.dart';
import '../entities/list_report.dart';
import '../entities/list_report_row.dart';

/// Agrega tempo **estimado × real** por lista **dentro de um período**, a partir
/// dos registros de tempo datados (`TimeEntry`). A soma é feita aqui (domínio).
///
/// Semântica (decisão de produto, H7):
/// - **real** = soma dos minutos de todos os registros do período (folhas **e**
///   compromissos entram no relatório por lista — ver H14);
/// - **estimado** = soma do `estimatedMinutes` das **folhas que tiveram algum
///   tempo no período** (folhas sem registro no período não contam; compromissos
///   não têm "estimado"). Alinha estimado e real sobre o mesmo conjunto de folhas.
@lazySingleton
class GetListReportUseCase {
  const GetListReportUseCase();

  ListReport call(
    List<TimeEntryEntity> entries,
    List<TaskEntity> tasks,
    List<TaskListEntity> lists,
  ) {
    final names = {for (final l in lists) l.id: l.name};
    final tasksById = {for (final t in tasks) t.id: t};

    final spent = <String, int>{};
    // Ids de folhas (tarefas) que registraram tempo no período.
    final leavesWithTime = <String>{};

    for (final e in entries) {
      spent[e.listId] = (spent[e.listId] ?? 0) + e.minutes;
      if (e.targetType == TimerTargetTypeEnum.task) {
        leavesWithTime.add(e.targetId);
      }
    }

    final estimated = <String, int>{};
    for (final id in leavesWithTime) {
      final t = tasksById[id];
      if (t == null || t.hasChildren) continue; // só folhas existentes
      estimated[t.listId] = (estimated[t.listId] ?? 0) + (t.estimatedMinutes ?? 0);
    }

    final rows = <ListReportRow>[];
    final listIds = {...spent.keys, ...estimated.keys};
    for (final id in listIds) {
      rows.add(ListReportRow(
        listId: id,
        listName: names[id] ?? 'Lista',
        estimatedMinutes: estimated[id] ?? 0,
        spentMinutes: spent[id] ?? 0,
      ));
    }

    rows.sort((a, b) => b.spentMinutes.compareTo(a.spentMinutes));
    return ListReport(rows);
  }
}
