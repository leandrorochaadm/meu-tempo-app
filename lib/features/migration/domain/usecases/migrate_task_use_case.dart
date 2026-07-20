import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../task/domain/entities/task_entity.dart';
import '../../../task/domain/repositories/task_repository.dart';

class MigrateTaskParams extends Equatable {
  const MigrateTaskParams({required this.task, required this.today});
  final TaskEntity task;
  final DateTime today;

  @override
  List<Object?> get props => [task, today];
}

/// Migra uma pendência: leva o prazo para **hoje** (a tarefa volta ao dia).
@lazySingleton
class MigrateTaskUseCase implements UseCase<Unit, MigrateTaskParams> {
  const MigrateTaskUseCase(this._repository);

  final TaskRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(MigrateTaskParams params) {
    final t = params.task;
    final today =
        DateTime(params.today.year, params.today.month, params.today.day);
    final migrated = TaskEntity(
      id: t.id,
      title: t.title,
      listId: t.listId,
      createdAt: t.createdAt,
      parentId: t.parentId,
      estimatedMinutes: t.estimatedMinutes,
      dueDate: today,
      importance: t.importance,
      isDone: t.isDone,
      hasChildren: t.hasChildren,
      spentMinutes: t.spentMinutes,
    );
    return _repository.update(migrated);
  }
}
