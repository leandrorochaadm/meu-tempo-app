import 'package:injectable/injectable.dart';

import '../../../task/domain/entities/task_entity.dart';

/// Folhas **não concluídas** com prazo anterior a hoje — pendências que o
/// usuário decide migrar ou descartar. Filtro puro (recebe `today`).
@lazySingleton
class GetPendingMigrationsUseCase {
  const GetPendingMigrationsUseCase();

  List<TaskEntity> call(List<TaskEntity> tasks, DateTime today) {
    final t0 = DateTime(today.year, today.month, today.day);
    return tasks.where((t) {
      if (t.hasChildren || t.isDone || t.dueDate == null) return false;
      final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return due.isBefore(t0);
    }).toList();
  }
}
