import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/appointment_entity.dart';
import '../failures.dart';
import '../repositories/appointment_repository.dart';

class CreateAppointmentParams extends Equatable {
  const CreateAppointmentParams({
    required this.title,
    required this.listId,
    required this.date,
    required this.startMinute,
    required this.durationMinutes,
  });

  final String title;
  final String listId;
  final DateTime date;
  final int startMinute;
  final int durationMinutes;

  @override
  List<Object?> get props =>
      [title, listId, date, startMinute, durationMinutes];
}

@lazySingleton
class CreateAppointmentUseCase
    implements UseCase<AppointmentEntity, CreateAppointmentParams> {
  const CreateAppointmentUseCase(this._repository);

  final AppointmentRepository _repository;

  @override
  Future<Either<Failure, AppointmentEntity>> call(
    CreateAppointmentParams params,
  ) {
    final title = params.title.trim();
    if (title.isEmpty) {
      return Future.value(const Left(EmptyAppointmentTitleFailure()));
    }
    if (params.durationMinutes <= 0) {
      return Future.value(const Left(InvalidAppointmentDurationFailure()));
    }
    final day = DateTime(params.date.year, params.date.month, params.date.day);
    return _repository.create(AppointmentEntity(
      id: '',
      title: title,
      listId: params.listId,
      date: day,
      startMinute: params.startMinute,
      durationMinutes: params.durationMinutes,
    ));
  }
}
