import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

/// Fluxo das tarefas do usuário.
@lazySingleton
class WatchTasksUseCase
    implements StreamUseCase<Either<Failure, List<TaskEntity>>, NoParams> {
  const WatchTasksUseCase(this._repository);

  final TaskRepository _repository;

  @override
  Stream<Either<Failure, List<TaskEntity>>> call(NoParams params) =>
      _repository.watchTasks();
}
