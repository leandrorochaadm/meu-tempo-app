part of 'agenda_bloc.dart';

sealed class AgendaState extends Equatable {
  const AgendaState();

  @override
  List<Object?> get props => const [];
}

class AgendaLoading extends AgendaState {
  const AgendaLoading();
}

class AgendaLoaded extends AgendaState {
  const AgendaLoaded({required this.appointments, required this.fit});

  final List<AppointmentEntity> appointments;
  final DayFit fit;

  @override
  List<Object?> get props => [appointments, fit];
}

class AgendaError extends AgendaState {
  const AgendaError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
