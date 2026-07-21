import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/importance_enum.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';
import '../task_failures.dart';

class EditTaskParams extends Equatable {
  const EditTaskParams({
    required this.taskId,
    required this.title,
    this.estimatedMinutes,
    this.dueDate,
    this.importance,
    this.listId,
  });

  final String taskId;
  final String title;
  final int? estimatedMinutes;
  final DateTime? dueDate;
  final ImportanceEnum? importance;
  final String? listId;

  @override
  List<Object?> get props =>
      [taskId, title, estimatedMinutes, dueDate, importance, listId];
}

/// Edita os campos de uma tarefa (título e, na folha, tempo/prazo/importância/
/// lista). Recalcula prioridade indiretamente (a listagem reordena na abertura).
@lazySingleton
class EditTaskUseCase implements UseCase<Unit, EditTaskParams> {
  const EditTaskUseCase(this._repository);

  final TaskRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(EditTaskParams params) async {
    final title = params.title.trim();
    if (title.isEmpty) return const Left(EmptyTitleFailure());

    final result = await _repository.getTasks();
    final failure = result.getLeft().toNullable();
    if (failure != null) return Left(failure);
    final tasks = result.getRight().toNullable()!;

    TaskEntity? task;
    for (final t in tasks) {
      if (t.id == params.taskId) {
        task = t;
        break;
      }
    }
    if (task == null) return const Left(TaskNotFoundFailure());

    final newListId = params.listId ?? task.listId;

    final edited = TaskEntity(
      id: task.id,
      title: title,
      listId: newListId,
      createdAt: task.createdAt,
      parentId: task.parentId,
      estimatedMinutes: params.estimatedMinutes ?? task.estimatedMinutes,
      dueDate: params.dueDate ?? task.dueDate,
      importance: params.importance ?? task.importance,
      isDone: task.isDone,
      hasChildren: task.hasChildren,
      spentMinutes: task.spentMinutes,
    );

    final upd = await _repository.update(edited);
    final updFailure = upd.getLeft().toNullable();
    if (updFailure != null) return Left(updFailure);

    // Regra: trocar a lista de uma mãe/avó propaga para todas as filhas/netas.
    // Só varre quando é mãe (tem filhas) e a lista realmente mudou — evita N
    // escritas inúteis a cada edição de folha.
    if (task.hasChildren && task.listId != newListId) {
      final descendants = _descendantsOf(task.id, tasks);
      for (final d in descendants) {
        final moved = TaskEntity(
          id: d.id,
          title: d.title,
          listId: newListId,
          createdAt: d.createdAt,
          parentId: d.parentId,
          estimatedMinutes: d.estimatedMinutes,
          dueDate: d.dueDate,
          importance: d.importance,
          isDone: d.isDone,
          hasChildren: d.hasChildren,
          spentMinutes: d.spentMinutes,
        );
        final res = await _repository.update(moved);
        final f = res.getLeft().toNullable();
        if (f != null) return Left(f);
      }
    }

    return const Right(unit);
  }

  /// Todos os descendentes (filhas e netas) de [rootId], via `parentId`.
  List<TaskEntity> _descendantsOf(String rootId, List<TaskEntity> tasks) {
    final childrenOf = <String, List<TaskEntity>>{};
    for (final t in tasks) {
      if (t.parentId != null) {
        childrenOf.putIfAbsent(t.parentId!, () => []).add(t);
      }
    }
    final out = <TaskEntity>[];
    void visit(String id) {
      for (final c in childrenOf[id] ?? const <TaskEntity>[]) {
        out.add(c);
        visit(c.id);
      }
    }

    visit(rootId);
    return out;
  }
}
