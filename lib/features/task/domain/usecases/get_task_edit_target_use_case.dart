import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../list/domain/repositories/task_list_repository.dart';
import '../entities/task_edit_target_entity.dart';
import '../repositories/task_repository.dart';
import '../task_failures.dart';
import 'get_task_edit_context_use_case.dart';

class GetTaskEditTargetParams extends Equatable {
  const GetTaskEditTargetParams({required this.taskId});

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

/// Resolves, by id only, what the edit screen needs — used when the task is
/// opened from outside the list (tap on the lock screen timer, deep link,
/// browser refresh). Reads all tasks (including done) and the lists, and reuses
/// the parent candidates rule of [GetTaskEditContextUseCase]. Deleted task →
/// [TaskNotFoundFailure].
@lazySingleton
class GetTaskEditTargetUseCase
    implements UseCase<TaskEditTargetEntity, GetTaskEditTargetParams> {
  const GetTaskEditTargetUseCase(
    this._taskRepository,
    this._taskListRepository,
    this._getEditContext,
  );

  final TaskRepository _taskRepository;
  final TaskListRepository _taskListRepository;
  final GetTaskEditContextUseCase _getEditContext;

  @override
  Future<Either<Failure, TaskEditTargetEntity>> call(
    GetTaskEditTargetParams params,
  ) async {
    final tasksResult = await _taskRepository.getTasks();
    final tasksFailure = tasksResult.getLeft().toNullable();
    if (tasksFailure != null) return Left(tasksFailure);

    final listsResult = await _taskListRepository.getLists();
    final listsFailure = listsResult.getLeft().toNullable();
    if (listsFailure != null) return Left(listsFailure);

    final editContext = _getEditContext(
      params.taskId,
      tasksResult.getRight().toNullable() ?? const [],
    );
    if (editContext == null) return const Left(TaskNotFoundFailure());
    return Right(TaskEditTargetEntity(
      editContext: editContext,
      lists: listsResult.getRight().toNullable() ?? const [],
    ));
  }
}
