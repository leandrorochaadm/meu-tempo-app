import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/time_entry_entity.dart';
import '../entities/time_entry_origin_enum.dart';
import '../entities/timer_target_type_enum.dart';
import '../repositories/task_repository.dart';
import '../repositories/time_entry_repository.dart';
import '../task_failures.dart';

class RegisterManualTimeParams extends Equatable {
  const RegisterManualTimeParams({
    required this.targetId,
    required this.targetIsLeaf,
    required this.listId,
    required this.minutes,
    required this.now,
  });

  final String targetId;
  final bool targetIsLeaf;

  /// Lista da folha — necessária para o registro de tempo datado do relatório.
  final String listId;
  final int minutes;
  final DateTime now;

  @override
  List<Object?> get props => [targetId, targetIsLeaf, listId, minutes, now];
}

/// Registra tempo manualmente numa folha (ex.: atalhos +15/+30 min). Além de
/// somar ao acumulado da folha, grava o registro datado para o relatório.
@lazySingleton
class RegisterManualTimeUseCase
    implements UseCase<Unit, RegisterManualTimeParams> {
  const RegisterManualTimeUseCase(this._taskRepository, this._timeEntryRepository);

  final TaskRepository _taskRepository;
  final TimeEntryRepository _timeEntryRepository;

  @override
  Future<Either<Failure, Unit>> call(RegisterManualTimeParams params) async {
    if (!params.targetIsLeaf) return const Left(TimerOnNonLeafFailure());
    if (params.minutes <= 0) return const Left(InvalidDurationFailure());

    final result =
        await _taskRepository.addSpentMinutes(params.targetId, params.minutes);
    final failure = result.getLeft().toNullable();
    if (failure != null) return Left(failure);

    await _timeEntryRepository.add(TimeEntryEntity(
      id: '',
      targetId: params.targetId,
      targetType: TimerTargetTypeEnum.task,
      listId: params.listId,
      minutes: params.minutes,
      origin: TimeEntryOriginEnum.manual,
      occurredAt: params.now,
    ));
    return const Right(unit);
  }
}
