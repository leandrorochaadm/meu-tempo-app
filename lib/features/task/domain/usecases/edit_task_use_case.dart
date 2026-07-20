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

    final edited = TaskEntity(
      id: task.id,
      title: title,
      listId: params.listId ?? task.listId,
      createdAt: task.createdAt,
      parentId: task.parentId,
      estimatedMinutes: params.estimatedMinutes ?? task.estimatedMinutes,
      dueDate: params.dueDate ?? task.dueDate,
      importance: params.importance ?? task.importance,
      isDone: task.isDone,
      hasChildren: task.hasChildren,
      spentMinutes: task.spentMinutes,
    );

    return _repository.update(edited);
  }
}
