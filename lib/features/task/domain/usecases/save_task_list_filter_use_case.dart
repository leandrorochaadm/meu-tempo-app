import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/task_list_filter_repository.dart';

class SaveTaskListFilterParams extends Equatable {
  const SaveTaskListFilterParams(this.listId);

  /// Lista a fixar como filtro (`null` limpa → "Todas as listas").
  final String? listId;

  @override
  List<Object?> get props => [listId];
}

/// Persiste o filtro de lista escolhido na tela principal.
@lazySingleton
class SaveTaskListFilterUseCase
    implements UseCase<Unit, SaveTaskListFilterParams> {
  const SaveTaskListFilterUseCase(this._repository);

  final TaskListFilterRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SaveTaskListFilterParams params) =>
      _repository.setSelectedListId(params.listId);
}
