import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/appointment_repository.dart';

class SetAppointmentDoneParams extends Equatable {
  const SetAppointmentDoneParams({
    required this.appointmentId,
    required this.done,
  });

  final String appointmentId;

  /// `true` conclui; `false` reabre.
  final bool done;

  @override
  List<Object?> get props => [appointmentId, done];
}

/// Conclui ou reabre um compromisso (req. 10 e 14). Compromisso não tem mãe,
/// então não há propagação como no `CompleteTaskUseCase`: a qualquer momento
/// ele pode ser concluído ou reaberto. Não mexe no cronômetro — parar e
/// concluir juntos é o `FinishTimerUseCase` (passo 05).
@lazySingleton
class SetAppointmentDoneUseCase
    implements UseCase<Unit, SetAppointmentDoneParams> {
  const SetAppointmentDoneUseCase(this._repository);

  final AppointmentRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SetAppointmentDoneParams params) =>
      _repository.setDone(params.appointmentId, params.done);
}
