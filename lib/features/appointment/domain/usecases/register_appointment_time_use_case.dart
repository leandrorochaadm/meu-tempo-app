import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../task/domain/entities/time_entry_entity.dart';
import '../../../task/domain/entities/time_entry_origin_enum.dart';
import '../../../task/domain/entities/timer_target_type_enum.dart';
import '../../../task/domain/repositories/time_entry_repository.dart';
import '../failures.dart';
import '../repositories/appointment_repository.dart';

class RegisterAppointmentTimeParams extends Equatable {
  const RegisterAppointmentTimeParams({
    required this.appointmentId,
    required this.listId,
    required this.minutes,
    required this.now,
  });

  final String appointmentId;
  final String listId;
  final int minutes;
  final DateTime now;

  @override
  List<Object?> get props => [appointmentId, listId, minutes, now];
}

/// Registra tempo manualmente num compromisso. Soma ao acumulado e grava o
/// registro de tempo datado (entra no relatório por lista/período).
@lazySingleton
class RegisterAppointmentTimeUseCase
    implements UseCase<Unit, RegisterAppointmentTimeParams> {
  const RegisterAppointmentTimeUseCase(
    this._appointmentRepository,
    this._timeEntryRepository,
  );

  final AppointmentRepository _appointmentRepository;
  final TimeEntryRepository _timeEntryRepository;

  @override
  Future<Either<Failure, Unit>> call(
    RegisterAppointmentTimeParams params,
  ) async {
    if (params.minutes <= 0) {
      return const Left(InvalidAppointmentDurationFailure());
    }

    final result = await _appointmentRepository.addSpentMinutes(
      params.appointmentId,
      params.minutes,
    );
    final failure = result.getLeft().toNullable();
    if (failure != null) return Left(failure);

    await _timeEntryRepository.add(TimeEntryEntity(
      id: '',
      targetId: params.appointmentId,
      targetType: TimerTargetTypeEnum.appointment,
      listId: params.listId,
      minutes: params.minutes,
      origin: TimeEntryOriginEnum.manual,
      occurredAt: params.now,
    ));
    return const Right(unit);
  }
}
