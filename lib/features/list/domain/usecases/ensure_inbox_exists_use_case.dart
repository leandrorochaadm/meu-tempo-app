import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_defaults.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/task_list_entity.dart';
import '../repositories/task_list_repository.dart';

/// Regra de fluxo: garante que a lista "Entrada" (default) exista.
/// Lê as listas; se não houver nenhuma `isDefault`, cria a "Entrada".
@lazySingleton
class EnsureInboxExistsUseCase implements UseCase<TaskListEntity, NoParams> {
  const EnsureInboxExistsUseCase(this._repository);

  final TaskListRepository _repository;

  @override
  Future<Either<Failure, TaskListEntity>> call(NoParams params) async {
    final result = await _repository.getLists();
    return result.fold(
      (failure) async => Left<Failure, TaskListEntity>(failure),
      (lists) async {
        for (final list in lists) {
          if (list.isDefault) {
            return Right<Failure, TaskListEntity>(list);
          }
        }
        return _repository.create(
          const TaskListEntity(
            id: '',
            name: AppDefaults.inboxListName,
            isDefault: true,
          ),
        );
      },
    );
  }
}
