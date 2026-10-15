import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/recurring_task_entity.dart';
import '../repositories/recurring_task_repository.dart';

class RestoreRecurringTaskParams extends Equatable {
  const RestoreRecurringTaskParams({required this.template});

  final RecurringTaskEntity template;

  @override
  List<Object?> get props => [template];
}

/// Desfaz a exclusão de um modelo, recriando-o com o mesmo `id`, `createdAt` e
/// `lastGeneratedOn`.
@lazySingleton
class RestoreRecurringTaskUseCase
    implements UseCase<Unit, RestoreRecurringTaskParams> {
  const RestoreRecurringTaskUseCase(this._repository);

  final RecurringTaskRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(RestoreRecurringTaskParams params) =>
      _repository.restore(params.template);
}
