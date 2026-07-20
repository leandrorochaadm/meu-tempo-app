import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../task/domain/entities/task_entity.dart';
import '../../../task/domain/repositories/task_repository.dart';
import '../entities/task_list_entity.dart';
import '../list_failures.dart';
import '../repositories/task_list_repository.dart';

class DeleteListParams extends Equatable {
  const DeleteListParams({required this.listId, this.moveToListId});

  final String listId;

  /// Se informado, as tarefas da lista são movidas para lá; se `null`, são
  /// excluídas.
  final String? moveToListId;

  @override
  List<Object?> get props => [listId, moveToListId];
}

/// Exclui uma lista tratando as tarefas dela: **mover** para outra lista ou
/// **excluir todas**. A lista fixa "Entrada" não pode ser excluída.
@lazySingleton
class DeleteListUseCase implements UseCase<Unit, DeleteListParams> {
  const DeleteListUseCase(this._listRepository, this._taskRepository);

  final TaskListRepository _listRepository;
  final TaskRepository _taskRepository;

  @override
  Future<Either<Failure, Unit>> call(DeleteListParams params) async {
    final listsResult = await _listRepository.getLists();
    final listsFailure = listsResult.getLeft().toNullable();
    if (listsFailure != null) return Left(listsFailure);
    final lists = listsResult.getRight().toNullable()!;

    TaskListEntity? target;
    for (final l in lists) {
      if (l.id == params.listId) {
        target = l;
        break;
      }
    }
    if (target == null) return const Left(ListNotFoundFailure());
    if (target.isDefault) return const Left(CannotDeleteInboxFailure());

    final tasksResult = await _taskRepository.getTasks();
    final tasksFailure = tasksResult.getLeft().toNullable();
    if (tasksFailure != null) return Left(tasksFailure);
    final tasks = tasksResult
        .getRight()
        .toNullable()!
        .where((t) => t.listId == params.listId)
        .toList();

    for (final task in tasks) {
      final res = params.moveToListId != null
          ? await _taskRepository.update(_withList(task, params.moveToListId!))
          : await _taskRepository.delete(task.id);
      final f = res.getLeft().toNullable();
      if (f != null) return Left(f);
    }

    return _listRepository.delete(params.listId);
  }

  TaskEntity _withList(TaskEntity t, String listId) => TaskEntity(
        id: t.id,
        title: t.title,
        listId: listId,
        createdAt: t.createdAt,
        parentId: t.parentId,
        estimatedMinutes: t.estimatedMinutes,
        dueDate: t.dueDate,
        importance: t.importance,
        isDone: t.isDone,
        hasChildren: t.hasChildren,
        spentMinutes: t.spentMinutes,
      );
}
