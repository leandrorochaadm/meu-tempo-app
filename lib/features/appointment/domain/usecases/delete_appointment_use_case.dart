import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/appointment_repository.dart';

class DeleteAppointmentParams extends Equatable {
  const DeleteAppointmentParams(this.appointmentId);
  final String appointmentId;

  @override
  List<Object?> get props => [appointmentId];
}

@lazySingleton
class DeleteAppointmentUseCase
    implements UseCase<Unit, DeleteAppointmentParams> {
  const DeleteAppointmentUseCase(this._repository);

  final AppointmentRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(DeleteAppointmentParams params) =>
      _repository.delete(params.appointmentId);
}
