import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/recurring_task_repository.dart';

class DeleteRecurringTaskParams extends Equatable {
  const DeleteRecurringTaskParams({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Exclui um modelo de tarefa recorrente. As tarefas já geradas permanecem
/// (R6); o desfazer usa o `RestoreRecurringTaskUseCase` com a entity que a tela
/// já tem.
@lazySingleton
class DeleteRecurringTaskUseCase
    implements UseCase<Unit, DeleteRecurringTaskParams> {
  const DeleteRecurringTaskUseCase(this._repository);

  final RecurringTaskRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(DeleteRecurringTaskParams params) =>
      _repository.delete(params.id);
}
