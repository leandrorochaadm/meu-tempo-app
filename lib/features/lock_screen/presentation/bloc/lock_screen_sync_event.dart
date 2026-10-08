part of 'lock_screen_sync_bloc.dart';

sealed class LockScreenSyncEvent extends Equatable {
  const LockScreenSyncEvent();

  @override
  List<Object?> get props => const [];
}

/// Signed-in user (on sign-in or when the app opens already signed in): starts
/// mirroring the active timer on the lock screen. Resubscribes from scratch if
/// it was already mirroring.
class LockScreenSyncStarted extends LockScreenSyncEvent {
  const LockScreenSyncStarted();
}

/// The app came back to the foreground: resubscribes and redraws the lock
/// screen with the current timer ("two phones" rule). Also resumes syncing
/// after a read failure. Ignored while signed out.
class LockScreenSyncAppResumed extends LockScreenSyncEvent {
  const LockScreenSyncAppResumed();
}

/// Signed-out user (left or opened the app signed out): stops mirroring and
/// removes the timer from the lock screen.
class LockScreenSyncSignedOut extends LockScreenSyncEvent {
  const LockScreenSyncSignedOut();
}

/// Internal: the stream of the timer on screen emitted. [generation] identifies
/// the subscription that produced the event; events of old subscriptions are
/// dropped.
class _LockScreenSyncTimerChanged extends LockScreenSyncEvent {
  const _LockScreenSyncTimerChanged(this.timer, this.generation);

  final LockScreenTimerEntity? timer;
  final int generation;

  @override
  List<Object?> get props => [timer, generation];
}
