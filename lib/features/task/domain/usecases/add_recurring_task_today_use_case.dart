import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/recurring_task_entity.dart';
import '../entities/task_entity.dart';
import '../repositories/recurring_task_repository.dart';
import '../repositories/task_repository.dart';
import '../task_failures.dart';
import 'create_task_use_case.dart';

class AddRecurringTaskTodayParams extends Equatable {
  const AddRecurringTaskTodayParams({
    required this.template,
    required this.today,
    this.confirmed = false,
  });

  final RecurringTaskEntity template;

  /// "Hoje" injetado; vira `createdAt` e `dueDate` da tarefa.
  final DateTime today;

  /// `true` quando o usuário já respondeu "Criar mesmo assim?" (R4) ou
  /// quando a geração automática já checou a pendência (R5).
  final bool confirmed;

  @override
  List<Object?> get props => [template, today, confirmed];
}

/// Transforma um modelo recorrente em tarefa de hoje (R4, R6, H15). É o único
/// lugar que faz essa conversão. Modelo com dias marcados e instância pendente
/// devolve [PendingRecurringInstanceFailure], a menos que `confirmed`.
@lazySingleton
class AddRecurringTaskTodayUseCase
    implements UseCase<TaskEntity, AddRecurringTaskTodayParams> {
  const AddRecurringTaskTodayUseCase(
    this._taskRepository,
    this._recurringRepository,
    this._createTask,
  );

  final TaskRepository _taskRepository;
  final RecurringTaskRepository _recurringRepository;
  final CreateTaskUseCase _createTask;

  @override
  Future<Either<Failure, TaskEntity>> call(
    AddRecurringTaskTodayParams params,
  ) async {
    final template = params.template;
    if (template.isScheduled && !params.confirmed) {
      final tasksResult = await _taskRepository.getTasks();
      final failure = tasksResult.getLeft().toNullable();
      if (failure != null) return Left(failure);
      final tasks = tasksResult.getRight().toNullable()!;
      if (tasks.any((t) => t.isPendingInstanceOf(template.id))) {
        return const Left(PendingRecurringInstanceFailure());
      }
    }

    final created = await _createTask(
      CreateTaskParams(
        title: template.title,
        listId: template.listId,
        today: params.today,
        estimatedMinutes: template.estimatedMinutes,
        dueDate: params.today,
        importance: template.importance,
        recurringTaskId: template.id,
      ),
    );
    if (created.isRight() && template.isDueOn(params.today)) {
      // A manual no dia agendado conta como "gerada hoje" (R4).
      // Resultado ignorado (true, false ou Left): a tarefa já existe.
      await _recurringRepository.claimGeneration(template.id, params.today);
    }
    return created;
  }
}
