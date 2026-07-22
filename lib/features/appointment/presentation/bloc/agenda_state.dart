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
  const AgendaLoaded({
    required this.appointments,
    required this.fit,
    this.activeAppointmentId,
    this.activeTimerStartedAt,
  });

  final List<AppointmentEntity> appointments;
  final DayFit fit;

  /// Compromisso com cronômetro em andamento (`null` quando nenhum).
  final String? activeAppointmentId;

  /// Início da sessão do cronômetro ativo (`null` quando nenhum) — base do
  /// contador ao vivo hh:mm:ss no selo do compromisso em execução.
  final DateTime? activeTimerStartedAt;

  @override
  List<Object?> get props =>
      [appointments, fit, activeAppointmentId, activeTimerStartedAt];
}

class AgendaError extends AgendaState {
  const AgendaError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
