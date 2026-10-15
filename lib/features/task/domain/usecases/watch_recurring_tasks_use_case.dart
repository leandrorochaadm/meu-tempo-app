import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/recurring_task_entity.dart';
import '../repositories/recurring_task_repository.dart';

/// Fluxo dos modelos de tarefa recorrente do usuário (H15).
@lazySingleton
class WatchRecurringTasksUseCase
    implements
        StreamUseCase<Either<Failure, List<RecurringTaskEntity>>, NoParams> {
  const WatchRecurringTasksUseCase(this._repository);

  final RecurringTaskRepository _repository;

  @override
  Stream<Either<Failure, List<RecurringTaskEntity>>> call(NoParams params) =>
      _repository.watchAll();
}
