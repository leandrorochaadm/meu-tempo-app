part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => const [];
}

class SettingsStarted extends SettingsEvent {
  const SettingsStarted();
}

class SettingsConfigUpdated extends SettingsEvent {
  const SettingsConfigUpdated(this.result);
  final Either<Failure, DayConfigEntity> result;

  @override
  List<Object?> get props => [result];
}

class AvailableMinutesChanged extends SettingsEvent {
  const AvailableMinutesChanged(this.minutes);
  final int minutes;

  @override
  List<Object?> get props => [minutes];
}
