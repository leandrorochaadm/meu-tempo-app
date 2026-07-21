import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../appointment/domain/repositories/appointment_repository.dart';
import '../entities/time_entry_entity.dart';
import '../entities/time_entry_origin_enum.dart';
import '../entities/timer_target_type_enum.dart';
import '../repositories/task_repository.dart';
import '../repositories/time_entry_repository.dart';
import '../repositories/timer_repository.dart';

class StopTimerParams extends Equatable {
  const StopTimerParams({required this.now});
  final DateTime now;

  @override
  List<Object?> get props => [now];
}

/// Para o cronômetro ativo, somando o tempo decorrido ao alvo correto (tarefa
/// ou compromisso) e gravando o registro de tempo datado.
@lazySingleton
class StopTimerUseCase implements UseCase<Unit, StopTimerParams> {
  const StopTimerUseCase(
    this._timerRepository,
    this._taskRepository,
    this._appointmentRepository,
    this._timeEntryRepository,
  );

  final TimerRepository _timerRepository;
  final TaskRepository _taskRepository;
  final AppointmentRepository _appointmentRepository;
  final TimeEntryRepository _timeEntryRepository;

  @override
  Future<Either<Failure, Unit>> call(StopTimerParams params) async {
    final activeResult = await _timerRepository.getActive();
    final failure = activeResult.getLeft().toNullable();
    if (failure != null) return Left(failure);

    final active = activeResult.getRight().toNullable();
    if (active == null) return const Right(unit); // nada rodando

    final elapsed = active.elapsedMinutes(params.now);
    if (elapsed > 0) {
      if (active.targetType == TimerTargetTypeEnum.task) {
        await _taskRepository.addSpentMinutes(active.targetId, elapsed);
      } else {
        await _appointmentRepository.addSpentMinutes(active.targetId, elapsed);
      }
      await _timeEntryRepository.add(TimeEntryEntity(
        id: '',
        targetId: active.targetId,
        targetType: active.targetType,
        listId: active.listId,
        minutes: elapsed,
        origin: TimeEntryOriginEnum.timer,
        occurredAt: params.now,
      ));
    }
    return _timerRepository.clear();
  }
}
