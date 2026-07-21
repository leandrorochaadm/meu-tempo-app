import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class DeleteTaskParams extends Equatable {
  const DeleteTaskParams({required this.taskId});
  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

/// Exclui uma tarefa **em cascata** (ela e todas as filhas/netas). Se o pai
/// ficar sem filhas, seu `hasChildren` é atualizado. Devolve a subárvore
/// removida (raiz primeiro) para permitir **desfazer** (`RestoreTasksUseCase`).
@lazySingleton
class DeleteTaskUseCase
    implements UseCase<List<TaskEntity>, DeleteTaskParams> {
  const DeleteTaskUseCase(this._repository);

  final TaskRepository _repository;

  @override
  Future<Either<Failure, List<TaskEntity>>> call(
    DeleteTaskParams params,
  ) async {
    final result = await _repository.getTasks();
    final failure = result.getLeft().toNullable();
    if (failure != null) return Left(failure);
    final tasks = result.getRight().toNullable()!;

    final byId = {for (final t in tasks) t.id: t};
    final target = byId[params.taskId];

    final childrenOf = <String, List<TaskEntity>>{};
    for (final t in tasks) {
      if (t.parentId != null) {
        childrenOf.putIfAbsent(t.parentId!, () => []).add(t);
      }
    }

    // Coleta a subárvore (o alvo + descendentes) por BFS.
    final toDelete = <String>[];
    final queue = <String>[params.taskId];
    while (queue.isNotEmpty) {
      final id = queue.removeLast();
      toDelete.add(id);
      for (final c in childrenOf[id] ?? const <TaskEntity>[]) {
        queue.add(c.id);
      }
    }

    for (final id in toDelete) {
      final res = await _repository.delete(id);
      final f = res.getLeft().toNullable();
      if (f != null) return Left(f);
    }

    // Se o pai ficou sem outras filhas, marca hasChildren = false.
    final parentId = target?.parentId;
    if (parentId != null) {
      final remaining = (childrenOf[parentId] ?? const [])
          .where((c) => c.id != params.taskId)
          .isNotEmpty;
      if (!remaining) {
        await _repository.setHasChildren(parentId, false);
      }
    }

    // Subárvore removida (raiz primeiro), para o undo recriar preservando ids.
    final removed = [for (final id in toDelete) byId[id]!];
    return Right(removed);
  }
}
