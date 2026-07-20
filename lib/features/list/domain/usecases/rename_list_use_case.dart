import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../list_failures.dart';
import '../repositories/task_list_repository.dart';

class RenameListParams extends Equatable {
  const RenameListParams({required this.listId, required this.name});
  final String listId;
  final String name;

  @override
  List<Object?> get props => [listId, name];
}

/// Renomeia uma lista.
@lazySingleton
class RenameListUseCase implements UseCase<Unit, RenameListParams> {
  const RenameListUseCase(this._repository);

  final TaskListRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(RenameListParams params) {
    final name = params.name.trim();
    if (name.isEmpty) return Future.value(const Left(EmptyListNameFailure()));
    return _repository.rename(params.listId, name);
  }
}
