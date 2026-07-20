import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/task_list_entity.dart';
import '../list_failures.dart';
import '../repositories/task_list_repository.dart';

class CreateListParams extends Equatable {
  const CreateListParams({required this.name});
  final String name;

  @override
  List<Object?> get props => [name];
}

/// Cria uma nova lista (não-padrão).
@lazySingleton
class CreateListUseCase implements UseCase<TaskListEntity, CreateListParams> {
  const CreateListUseCase(this._repository);

  final TaskListRepository _repository;

  @override
  Future<Either<Failure, TaskListEntity>> call(CreateListParams params) {
    final name = params.name.trim();
    if (name.isEmpty) return Future.value(const Left(EmptyListNameFailure()));
    return _repository.create(TaskListEntity(id: '', name: name));
  }
}
