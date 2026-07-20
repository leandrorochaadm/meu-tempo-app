import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/task_list_entity.dart';
import '../repositories/task_list_repository.dart';

/// Fluxo das listas do usuário.
@lazySingleton
class WatchListsUseCase
    implements StreamUseCase<Either<Failure, List<TaskListEntity>>, NoParams> {
  const WatchListsUseCase(this._repository);

  final TaskListRepository _repository;

  @override
  Stream<Either<Failure, List<TaskListEntity>>> call(NoParams params) =>
      _repository.watchLists();
}
