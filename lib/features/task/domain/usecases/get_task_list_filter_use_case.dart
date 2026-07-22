import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/task_list_filter_repository.dart';

/// Lê o filtro de lista salvo (última lista usada). `Right(null)` = todas.
@lazySingleton
class GetTaskListFilterUseCase implements UseCase<String?, NoParams> {
  const GetTaskListFilterUseCase(this._repository);

  final TaskListFilterRepository _repository;

  @override
  Future<Either<Failure, String?>> call(NoParams params) =>
      _repository.getSelectedListId();
}
