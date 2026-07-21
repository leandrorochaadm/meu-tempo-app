part of 'time_entry_bloc.dart';

sealed class TimeEntryState extends Equatable {
  const TimeEntryState();

  @override
  List<Object?> get props => const [];
}

class TimeEntryLoading extends TimeEntryState {
  const TimeEntryLoading();
}

class TimeEntryLoaded extends TimeEntryState {
  const TimeEntryLoaded(this.entries);

  /// Registros da folha, mais recentes primeiro.
  final List<TimeEntryEntity> entries;

  @override
  List<Object?> get props => [entries];
}

class TimeEntryEmpty extends TimeEntryState {
  const TimeEntryEmpty();
}

class TimeEntryError extends TimeEntryState {
  const TimeEntryError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
