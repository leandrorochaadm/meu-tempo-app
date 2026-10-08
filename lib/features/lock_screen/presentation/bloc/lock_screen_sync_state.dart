part of 'lock_screen_sync_bloc.dart';

/// Last result confirmed by the gateway. No screen renders this state; it
/// exists for traceability and tests.
sealed class LockScreenSyncState extends Equatable {
  const LockScreenSyncState();

  @override
  List<Object?> get props => const [];
}

/// Signed out (or before authenticating): mirrors nothing.
class LockScreenSyncStopped extends LockScreenSyncState {
  const LockScreenSyncStopped();
}

/// Signed in, no timer on screen (the gateway confirmed the `clear`).
class LockScreenSyncHidden extends LockScreenSyncState {
  const LockScreenSyncHidden();
}

/// Signed in, with [timer] on screen (the gateway confirmed the `show`).
class LockScreenSyncVisible extends LockScreenSyncState {
  const LockScreenSyncVisible(this.timer);

  final LockScreenTimerEntity timer;

  @override
  List<Object?> get props => [timer];
}
