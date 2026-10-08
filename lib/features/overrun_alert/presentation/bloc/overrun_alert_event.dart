part of 'overrun_alert_bloc.dart';

sealed class OverrunAlertEvent extends Equatable {
  const OverrunAlertEvent();

  @override
  List<Object?> get props => const [];
}

/// Signed-in user: subscribes to the plan and to the alerts. Resubscribes from
/// scratch if it was already subscribed.
class OverrunAlertStarted extends OverrunAlertEvent {
  const OverrunAlertStarted();
}

/// Signed-out user: cancels everything.
class OverrunAlertSignedOut extends OverrunAlertEvent {
  const OverrunAlertSignedOut();
}

/// "Agora não": hides the banner until the next alert.
class OverrunAlertDismissed extends OverrunAlertEvent {
  const OverrunAlertDismissed();
}

/// "Pausar" on the banner.
class OverrunAlertPauseRequested extends OverrunAlertEvent {
  const OverrunAlertPauseRequested();
}

/// Internal: the plan stream emitted. [generation] identifies the subscription
/// that produced the event; events of old subscriptions are dropped.
class _OverrunAlertPlanChanged extends OverrunAlertEvent {
  const _OverrunAlertPlanChanged(this.plan, this.generation);

  final OverrunAlertPlanEntity? plan;
  final int generation;

  @override
  List<Object?> get props => [plan, generation];
}

/// Internal: an alert fired.
class _OverrunAlertFired extends OverrunAlertEvent {
  const _OverrunAlertFired(this.alert, this.generation);

  final OverrunAlertEntity alert;
  final int generation;

  @override
  List<Object?> get props => [alert, generation];
}
