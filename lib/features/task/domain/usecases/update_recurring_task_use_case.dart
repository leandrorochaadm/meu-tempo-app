import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/importance_enum.dart';
import '../entities/recurring_task_entity.dart';
import '../entities/weekday_enum.dart';
import '../repositories/recurring_task_repository.dart';
import '../task_failures.dart';

/// Parâmetros de edição de um modelo de tarefa recorrente.
class UpdateRecurringTaskParams extends Equatable {
  const UpdateRecurringTaskParams({
    required this.original,
    required this.title,
    required this.listId,
    required this.estimatedMinutes,
    required this.importance,
    required this.weekdays,
  });

  /// Modelo como estava antes da edição (fonte de `id`, `createdAt` e
  /// `lastGeneratedOn`).
  final RecurringTaskEntity original;
  final String title;
  final String listId;
  final int estimatedMinutes;
  final ImportanceEnum importance;
  final Set<WeekdayEnum> weekdays;

  @override
  List<Object?> get props => [
    original,
    title,
    listId,
    estimatedMinutes,
    importance,
    weekdays,
  ];
}

/// Edita um modelo de tarefa recorrente. Preserva `id`, `createdAt` e
/// `lastGeneratedOn`: mudar os dias depois da geração de hoje não gera outra
/// tarefa no mesmo dia (R3), e as tarefas já geradas não mudam (R6).
@lazySingleton
class UpdateRecurringTaskUseCase
    implements UseCase<RecurringTaskEntity, UpdateRecurringTaskParams> {
  const UpdateRecurringTaskUseCase(this._repository);

  final RecurringTaskRepository _repository;

  @override
  Future<Either<Failure, RecurringTaskEntity>> call(
    UpdateRecurringTaskParams params,
  ) async {
    final title = params.title.trim();
    if (title.isEmpty) return const Left(EmptyTitleFailure());
    if (params.estimatedMinutes <= 0) {
      return const Left(InvalidDurationFailure());
    }

    return _repository.update(
      RecurringTaskEntity(
        id: params.original.id,
        title: title,
        listId: params.listId,
        estimatedMinutes: params.estimatedMinutes,
        importance: params.importance,
        weekdays: params.weekdays,
        createdAt: params.original.createdAt,
        lastGeneratedOn: params.original.lastGeneratedOn,
      ),
    );
  }
}
