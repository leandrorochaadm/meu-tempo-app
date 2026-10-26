import 'models/task_model.dart';

/// Ordena um lote de criação com o pai antes da filha. Pai fora do conjunto
/// conta como já existente; ciclo ou pai que nunca entra vai ao fim.
List<TaskModel> orderParentsFirst(List<TaskModel> tasks) {
  final ids = {for (final t in tasks) t.id};
  final placed = <String>{};
  final result = <TaskModel>[];
  var remaining = List<TaskModel>.of(tasks);

  while (remaining.isNotEmpty) {
    final ready = <TaskModel>[];
    final waiting = <TaskModel>[];
    for (final task in remaining) {
      final parent = task.parentId;
      final canPlace =
          parent == null || !ids.contains(parent) || placed.contains(parent);
      (canPlace ? ready : waiting).add(task);
    }
    if (ready.isEmpty) {
      result.addAll(waiting);
      break;
    }
    for (final task in ready) {
      placed.add(task.id);
    }
    result.addAll(ready);
    remaining = waiting;
  }
  return result;
}
