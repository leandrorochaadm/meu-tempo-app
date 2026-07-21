import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/time_entry_entity.dart';
import '../repositories/task_repository.dart';
import '../repositories/time_entry_repository.dart';

class DeleteTimeEntryParams extends Equatable {
  const DeleteTimeEntryParams({required this.entry});

  /// Registro a excluir — traz `id`, `targetId` e `minutes` para o ajuste.
  final TimeEntryEntity entry;

  @override
  List<Object?> get props => [entry];
}

/// Exclui um registro de tempo e desconta seus minutos do acumulado da folha
/// (`addSpentMinutes(-minutes)`) — mantém o relatório por período coerente.
@lazySingleton
class DeleteTimeEntryUseCase implements UseCase<Unit, DeleteTimeEntryParams> {
  const DeleteTimeEntryUseCase(this._timeEntryRepository, this._taskRepository);

  final TimeEntryRepository _timeEntryRepository;
  final TaskRepository _taskRepository;

  @override
  Future<Either<Failure, Unit>> call(DeleteTimeEntryParams params) async {
    final entry = params.entry;
    final del = await _timeEntryRepository.delete(entry.id);
    final f = del.getLeft().toNullable();
    if (f != null) return Left(f);

    if (entry.minutes != 0) {
      return _taskRepository.addSpentMinutes(entry.targetId, -entry.minutes);
    }
    return const Right(unit);
  }
}
