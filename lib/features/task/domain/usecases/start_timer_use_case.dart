import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../appointment/domain/repositories/appointment_repository.dart';
import '../entities/active_timer_entity.dart';
import '../entities/time_entry_entity.dart';
import '../entities/time_entry_origin_enum.dart';
import '../entities/timer_target_type_enum.dart';
import '../repositories/task_repository.dart';
import '../repositories/time_entry_repository.dart';
import '../repositories/timer_repository.dart';
import '../task_failures.dart';

class StartTimerParams extends Equatable {
  const StartTimerParams({
    required this.targetId,
    required this.targetType,
    required this.targetIsLeaf,
    required this.listId,
    required this.now,
  });

  final String targetId;
  final TimerTargetTypeEnum targetType;

  /// Só relevante para tarefa (compromisso sempre pode ter cronômetro).
  final bool targetIsLeaf;

  /// Lista à qual o alvo pertence — persistida no cronômetro ativo para montar
  /// o registro de tempo ao pausar/parar.
  final String listId;
  final DateTime now;

  @override
  List<Object?> get props => [targetId, targetType, targetIsLeaf, listId, now];
}

/// Inicia o cronômetro numa folha ou compromisso. **Só 1 ativo por vez:** se já
/// houver outro rodando, ele é pausado, seu tempo decorrido é somado ao alvo
/// certo (tarefa ou compromisso) e um registro de tempo datado é gravado.
@lazySingleton
class StartTimerUseCase implements UseCase<Unit, StartTimerParams> {
  const StartTimerUseCase(
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
  Future<Either<Failure, Unit>> call(StartTimerParams params) async {
    // A trava de folha só vale para tarefa; compromisso sempre pode.
    if (params.targetType == TimerTargetTypeEnum.task && !params.targetIsLeaf) {
      return const Left(TimerOnNonLeafFailure());
    }

    final activeResult = await _timerRepository.getActive();
    final failure = activeResult.getLeft().toNullable();
    if (failure != null) return Left(failure);

    final active = activeResult.getRight().toNullable();
    if (active != null) {
      // Pausa o anterior, somando o tempo decorrido ao alvo correto.
      final elapsed = active.elapsedMinutes(params.now);
      if (elapsed > 0) {
        await _recordElapsed(active, elapsed, params.now);
      }
    }

    return _timerRepository.setActive(ActiveTimerEntity(
      targetId: params.targetId,
      targetType: params.targetType,
      listId: params.listId,
      startedAt: params.now,
    ));
  }

  /// Soma [elapsed] ao alvo do cronômetro [active] e grava o registro datado.
  Future<void> _recordElapsed(
    ActiveTimerEntity active,
    int elapsed,
    DateTime now,
  ) async {
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
      occurredAt: now,
    ));
  }
}
