part of 'settings_bloc.dart';

sealed class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => const [];
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  const SettingsLoaded(this.availableMinutesPerDay);
  final int availableMinutesPerDay;

  @override
  List<Object?> get props => [availableMinutesPerDay];
}

class SettingsError extends SettingsState {
  const SettingsError();
}
