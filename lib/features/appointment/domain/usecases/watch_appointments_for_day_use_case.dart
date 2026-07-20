import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/appointment_entity.dart';
import '../repositories/appointment_repository.dart';

class DayParams extends Equatable {
  const DayParams(this.day);
  final DateTime day;

  @override
  List<Object?> get props => [day];
}

@lazySingleton
class WatchAppointmentsForDayUseCase
    implements
        StreamUseCase<Either<Failure, List<AppointmentEntity>>, DayParams> {
  const WatchAppointmentsForDayUseCase(this._repository);

  final AppointmentRepository _repository;

  @override
  Stream<Either<Failure, List<AppointmentEntity>>> call(DayParams params) {
    final day =
        DateTime(params.day.year, params.day.month, params.day.day);
    return _repository.watchForDay(day);
  }
}
