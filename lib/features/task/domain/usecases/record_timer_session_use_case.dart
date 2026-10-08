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

class RecordTimerSessionParams extends Equatable {
  const RecordTimerSessionParams({required this.session, required this.now});

  /// Cronômetro cuja sessão termina agora (já reivindicado/trocado por quem chama).
  final ActiveTimerEntity session;
  final DateTime now;

  @override
  List<Object?> get props => [session, now];
}

/// Soma os minutos da sessão do cronômetro ao alvo certo (tarefa ou
/// compromisso) e grava o registro de tempo datado (origem `timer`). Sessão de
/// 0 minuto — inclusive a de um cronômetro pausado — não grava nada.
@lazySingleton
class RecordTimerSessionUseCase
    implements UseCase<Unit, RecordTimerSessionParams> {
  const RecordTimerSessionUseCase(
    this._taskRepository,
    this._appointmentRepository,
    this._timeEntryRepository,
  );

  final TaskRepository _taskRepository;
  final AppointmentRepository _appointmentRepository;
  final TimeEntryRepository _timeEntryRepository;

  @override
  Future<Either<Failure, Unit>> call(RecordTimerSessionParams params) async {
    final session = params.session;
    final minutes = session.elapsedMinutes(params.now);
    if (minutes <= 0) return const Right(unit);

    final added = switch (session.targetType) {
      TimerTargetTypeEnum.task =>
        await _taskRepository.addSpentMinutes(session.targetId, minutes),
      TimerTargetTypeEnum.appointment =>
        await _appointmentRepository.addSpentMinutes(session.targetId, minutes),
    };
    // O registro é gravado mesmo se a soma falhar (comportamento atual do
    // Start/Stop); a primeira falha é a devolvida.
    final recorded = await _timeEntryRepository.add(TimeEntryEntity(
      id: '',
      targetId: session.targetId,
      targetType: session.targetType,
      listId: session.listId,
      minutes: minutes,
      origin: TimeEntryOriginEnum.timer,
      occurredAt: params.now,
    ));
    return added.flatMap((_) => recorded);
  }
}
