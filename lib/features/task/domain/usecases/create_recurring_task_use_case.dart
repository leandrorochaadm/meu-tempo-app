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

/// Parâmetros de criação de um modelo de tarefa recorrente.
class CreateRecurringTaskParams extends Equatable {
  const CreateRecurringTaskParams({
    required this.title,
    required this.listId,
    required this.estimatedMinutes,
    required this.importance,
    required this.weekdays,
    required this.now,
  });

  final String title;
  final String listId;
  final int estimatedMinutes;
  final ImportanceEnum importance;

  /// Vazio = "sem dia fixo" (só pelo botão "Adicionar hoje") — válido (R2).
  final Set<WeekdayEnum> weekdays;

  /// "Agora" injetado (vira `createdAt`); `DateTime.now()` só no Bloc.
  final DateTime now;

  @override
  List<Object?> get props => [
    title,
    listId,
    estimatedMinutes,
    importance,
    weekdays,
    now,
  ];
}

/// Cria um modelo de tarefa recorrente (R1, R2).
@lazySingleton
class CreateRecurringTaskUseCase
    implements UseCase<RecurringTaskEntity, CreateRecurringTaskParams> {
  const CreateRecurringTaskUseCase(this._repository);

  final RecurringTaskRepository _repository;

  @override
  Future<Either<Failure, RecurringTaskEntity>> call(
    CreateRecurringTaskParams params,
  ) async {
    final title = params.title.trim();
    if (title.isEmpty) return const Left(EmptyTitleFailure());
    if (params.estimatedMinutes <= 0) {
      return const Left(InvalidDurationFailure());
    }

    return _repository.create(
      RecurringTaskEntity(
        id: '',
        title: title,
        listId: params.listId,
        estimatedMinutes: params.estimatedMinutes,
        importance: params.importance,
        weekdays: params.weekdays,
        createdAt: params.now,
      ),
    );
  }
}
