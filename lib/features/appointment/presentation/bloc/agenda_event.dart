part of 'agenda_bloc.dart';

sealed class AgendaEvent extends Equatable {
  const AgendaEvent();

  @override
  List<Object?> get props => const [];
}

class AgendaStarted extends AgendaEvent {
  const AgendaStarted();
}

class AgendaAppointmentsUpdated extends AgendaEvent {
  const AgendaAppointmentsUpdated(this.result);
  final Either<Failure, List<AppointmentEntity>> result;

  @override
  List<Object?> get props => [result];
}

class AgendaConfigUpdated extends AgendaEvent {
  const AgendaConfigUpdated(this.result);
  final Either<Failure, DayConfigEntity> result;

  @override
  List<Object?> get props => [result];
}

class AgendaTasksUpdated extends AgendaEvent {
  const AgendaTasksUpdated(this.result);
  final Either<Failure, List<TaskEntity>> result;

  @override
  List<Object?> get props => [result];
}

class AppointmentCreated extends AgendaEvent {
  const AppointmentCreated({
    required this.title,
    required this.startMinute,
    required this.durationMinutes,
  });

  final String title;
  final int startMinute;
  final int durationMinutes;

  @override
  List<Object?> get props => [title, startMinute, durationMinutes];
}

class AppointmentDeleted extends AgendaEvent {
  const AppointmentDeleted(this.appointmentId);
  final String appointmentId;

  @override
  List<Object?> get props => [appointmentId];
}

class AgendaActiveTimerUpdated extends AgendaEvent {
  const AgendaActiveTimerUpdated(this.result);
  final Either<Failure, ActiveTimerEntity?> result;

  @override
  List<Object?> get props => [result];
}

class AppointmentTimerStarted extends AgendaEvent {
  const AppointmentTimerStarted(this.appointmentId);
  final String appointmentId;

  @override
  List<Object?> get props => [appointmentId];
}

class AppointmentTimerStopped extends AgendaEvent {
  const AppointmentTimerStopped();
}
