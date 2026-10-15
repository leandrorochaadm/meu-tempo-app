import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/recurring_task_repository.dart';
import '../repositories/task_repository.dart';
import 'add_recurring_task_today_use_case.dart';

class MaterializeRecurringTasksParams extends Equatable {
  const MaterializeRecurringTasksParams({required this.today});

  final DateTime today;

  @override
  List<Object?> get props => [today];
}

/// Geração automática das tarefas recorrentes do dia (R3, R5, R7). Devolve
/// quantas tarefas criou. Pode rodar várias vezes no dia sem duplicar; sem
/// retroativo — só olha `today`.
@lazySingleton
class MaterializeRecurringTasksUseCase
    implements UseCase<int, MaterializeRecurringTasksParams> {
  const MaterializeRecurringTasksUseCase(
    this._recurringRepository,
    this._taskRepository,
    this._addToday,
  );

  final RecurringTaskRepository _recurringRepository;
  final TaskRepository _taskRepository;
  final AddRecurringTaskTodayUseCase _addToday;

  @override
  Future<Either<Failure, int>> call(
    MaterializeRecurringTasksParams params,
  ) async {
    final templatesResult = await _recurringRepository.getAll();
    final templatesFailure = templatesResult.getLeft().toNullable();
    if (templatesFailure != null) return Left(templatesFailure);
    final templates = templatesResult.getRight().toNullable()!;

    final tasksResult = await _taskRepository.getTasks();
    final tasksFailure = tasksResult.getLeft().toNullable();
    if (tasksFailure != null) return Left(tasksFailure);
    final tasks = tasksResult.getRight().toNullable()!;

    var created = 0;
    for (final template in templates) {
      if (!template.isDueOn(params.today)) continue;
      if (template.wasGeneratedOn(params.today)) continue;
      if (tasks.any((t) => t.isPendingInstanceOf(template.id))) continue;

      // Trava contra dois aparelhos: marca antes de criar.
      final claim = await _recurringRepository.claimGeneration(
        template.id,
        params.today,
      );
      final claimFailure = claim.getLeft().toNullable();
      if (claimFailure != null) return Left(claimFailure);
      if (!claim.getRight().toNullable()!) continue;

      final result = await _addToday(
        AddRecurringTaskTodayParams(
          template: template,
          today: params.today,
          confirmed: true,
        ),
      );
      final addFailure = result.getLeft().toNullable();
      if (addFailure != null) return Left(addFailure);
      created++;
    }
    return Right(created);
  }
}
