import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../task/domain/entities/task_entity.dart';
import '../../../task/domain/repositories/recurring_task_repository.dart';
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
/// **excluir todas**, e os modelos recorrentes dela seguem o mesmo destino.
/// A lista fixa "Entrada" não pode ser excluída.
@lazySingleton
class DeleteListUseCase implements UseCase<Unit, DeleteListParams> {
  const DeleteListUseCase(
    this._listRepository,
    this._taskRepository,
    this._recurringTaskRepository,
  );

  final TaskListRepository _listRepository;
  final TaskRepository _taskRepository;
  final RecurringTaskRepository _recurringTaskRepository;

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

    // Escrita **atômica**: como a lista pertence à árvore, mover (ou excluir)
    // metade das tarefas deixaria a árvore partida entre duas listas.
    if (tasks.isNotEmpty) {
      final res = params.moveToListId != null
          ? await _taskRepository.updateAll([
              for (final task in tasks) _withList(task, params.moveToListId!),
            ])
          : await _taskRepository.deleteSubtree([
              for (final task in tasks) task.id,
            ]);
      final f = res.getLeft().toNullable();
      if (f != null) return Left(f);
    }

    // Modelos recorrentes seguem as tarefas; sem isso a geração criaria tarefa
    // numa lista que não existe mais. Roda mesmo sem tarefas: a lista pode ter
    // só modelos.
    final templatesResult = params.moveToListId != null
        ? await _recurringTaskRepository.moveToList(
            params.listId,
            params.moveToListId!,
          )
        : await _recurringTaskRepository.deleteByList(params.listId);
    final templatesFailure = templatesResult.getLeft().toNullable();
    if (templatesFailure != null) return Left(templatesFailure);

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
    recurringTaskId: t.recurringTaskId,
  );
}
