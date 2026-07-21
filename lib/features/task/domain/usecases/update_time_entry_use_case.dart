import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/time_entry_entity.dart';
import '../repositories/task_repository.dart';
import '../repositories/time_entry_repository.dart';
import '../task_failures.dart';

class UpdateTimeEntryParams extends Equatable {
  const UpdateTimeEntryParams({
    required this.original,
    required this.newMinutes,
    required this.newOccurredAt,
  });

  /// Registro original — traz `id`, `minutes` antigos e os campos preservados.
  final TimeEntryEntity original;
  final int newMinutes;
  final DateTime newOccurredAt;

  @override
  List<Object?> get props => [original, newMinutes, newOccurredAt];
}

/// Edita um registro de tempo (minutos/data) e ajusta o acumulado da folha por
/// **delta** (`novo − antigo`), mantendo `soma(timeEntries) == spentMinutes`.
/// Preserva `origin`, `targetType`, `listId` e `id` do registro original.
@lazySingleton
class UpdateTimeEntryUseCase implements UseCase<Unit, UpdateTimeEntryParams> {
  const UpdateTimeEntryUseCase(this._timeEntryRepository, this._taskRepository);

  final TimeEntryRepository _timeEntryRepository;
  final TaskRepository _taskRepository;

  @override
  Future<Either<Failure, Unit>> call(UpdateTimeEntryParams params) async {
    if (params.newMinutes <= 0) return const Left(InvalidDurationFailure());

    final original = params.original;
    final updated = TimeEntryEntity(
      id: original.id,
      targetId: original.targetId,
      targetType: original.targetType,
      listId: original.listId,
      minutes: params.newMinutes,
      origin: original.origin,
      occurredAt: params.newOccurredAt,
    );

    final upd = await _timeEntryRepository.update(updated);
    final f = upd.getLeft().toNullable();
    if (f != null) return Left(f);

    final delta = params.newMinutes - original.minutes;
    if (delta != 0) {
      return _taskRepository.addSpentMinutes(original.targetId, delta);
    }
    return const Right(unit);
  }
}
