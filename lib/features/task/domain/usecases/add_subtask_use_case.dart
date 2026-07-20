import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';
import '../task_failures.dart';

class AddSubtaskParams extends Equatable {
  const AddSubtaskParams({
    required this.parentId,
    required this.parentLevel,
    required this.listId,
    required this.title,
    required this.today,
  });

  final String parentId;

  /// Nível do pai (0 = mãe, 1 = filha). Neta (2) não aceita filhas.
  final int parentLevel;
  final String listId;
  final String title;
  final DateTime today;

  @override
  List<Object?> get props => [parentId, parentLevel, listId, title, today];
}

/// Cria uma subtarefa (filha/neta) respeitando o limite de 3 níveis e marcando
/// o pai como tendo filhas.
@lazySingleton
class AddSubtaskUseCase implements UseCase<TaskEntity, AddSubtaskParams> {
  const AddSubtaskUseCase(this._repository);

  final TaskRepository _repository;

  @override
  Future<Either<Failure, TaskEntity>> call(AddSubtaskParams params) async {
    final title = params.title.trim();
    if (title.isEmpty) return const Left(EmptyTitleFailure());

    // mãe(0) → filha(1) → neta(2). Filha de neta (nível 3) é proibida.
    if (params.parentLevel + 1 > 2) {
      return const Left(MaxLevelExceededFailure());
    }

    final child = TaskEntity(
      id: '',
      title: title,
      listId: params.listId,
      createdAt: params.today,
      parentId: params.parentId,
      dueDate: params.today,
    );

    final created = await _repository.create(child);
    return created.fold(
      (failure) async => Left<Failure, TaskEntity>(failure),
      (task) async {
        // Marca o pai como não-folha; se falhar, ainda devolve a filha criada.
        await _repository.setHasChildren(params.parentId, true);
        return Right<Failure, TaskEntity>(task);
      },
    );
  }
}
