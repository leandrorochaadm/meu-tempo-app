import 'package:injectable/injectable.dart';

import '../../../list/domain/entities/task_list_entity.dart';
import '../../../task/domain/entities/task_entity.dart';
import '../entities/list_report_row.dart';

/// Agrega tempo **estimado × real** por lista, considerando as folhas (onde o
/// tempo vive). A soma é feita aqui (domínio), não na UI.
@lazySingleton
class GetListReportUseCase {
  const GetListReportUseCase();

  List<ListReportRow> call(
    List<TaskEntity> tasks,
    List<TaskListEntity> lists,
  ) {
    final names = {for (final l in lists) l.id: l.name};
    final estimated = <String, int>{};
    final spent = <String, int>{};

    for (final t in tasks) {
      if (t.hasChildren) continue; // só folhas carregam tempo
      estimated[t.listId] = (estimated[t.listId] ?? 0) + (t.estimatedMinutes ?? 0);
      spent[t.listId] = (spent[t.listId] ?? 0) + t.spentMinutes;
    }

    final rows = <ListReportRow>[];
    final listIds = {...estimated.keys, ...spent.keys};
    for (final id in listIds) {
      rows.add(ListReportRow(
        listId: id,
        listName: names[id] ?? 'Lista',
        estimatedMinutes: estimated[id] ?? 0,
        spentMinutes: spent[id] ?? 0,
      ));
    }

    rows.sort((a, b) => b.spentMinutes.compareTo(a.spentMinutes));
    return rows;
  }
}
