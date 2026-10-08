part of 'overrun_alert_bloc.dart';

sealed class OverrunAlertState extends Equatable {
  const OverrunAlertState();

  @override
  List<Object?> get props => const [];
}

/// No banner.
class OverrunAlertHidden extends OverrunAlertState {
  const OverrunAlertHidden();
}

/// Banner on screen for [alert].
class OverrunAlertVisible extends OverrunAlertState {
  const OverrunAlertVisible(this.alert);

  final OverrunAlertEntity alert;

  @override
  List<Object?> get props => [alert];
}

/// Pausing failed: the banner stays and [message] shows in a snackbar. Only
/// comes from [OverrunAlertVisible].
class OverrunAlertPauseFailed extends OverrunAlertState {
  const OverrunAlertPauseFailed(this.alert, this.message);

  final OverrunAlertEntity alert;
  final String message;

  @override
  List<Object?> get props => [alert, message];
}
