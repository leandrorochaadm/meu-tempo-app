part of 'lock_screen_permission_bloc.dart';

sealed class LockScreenPermissionEvent extends Equatable {
  const LockScreenPermissionEvent();

  @override
  List<Object?> get props => const [];
}

/// Signed-in user (`AuthAuthenticated`) with the shell mounted: starts watching
/// for starts made with the phone notifications off.
class LockScreenPermissionStarted extends LockScreenPermissionEvent {
  const LockScreenPermissionStarted();
}

/// App back to the foreground (e.g. coming back from the settings):
/// resubscribes to the starts and, with the banner in view, rereads the
/// permission. Ignored when signed out.
class LockScreenPermissionAppResumed extends LockScreenPermissionEvent {
  const LockScreenPermissionAppResumed();
}

/// Signed out (shell unmounted): stops watching and hides the banner.
class LockScreenPermissionStopped extends LockScreenPermissionEvent {
  const LockScreenPermissionStopped();
}

/// "Abrir Ajustes" banner button.
class LockScreenPermissionSettingsRequested extends LockScreenPermissionEvent {
  const LockScreenPermissionSettingsRequested();
}

/// "Agora não" banner button. The banner comes back on the next start.
class LockScreenPermissionBannerDismissed extends LockScreenPermissionEvent {
  const LockScreenPermissionBannerDismissed();
}

/// Internal: the domain warned about a start with notifications off.
/// [generation] identifies the subscription that produced it — a warning from
/// an old subscription is dropped.
class _LockScreenPermissionWarned extends LockScreenPermissionEvent {
  const _LockScreenPermissionWarned(this.generation);

  final int generation;

  @override
  List<Object?> get props => [generation];
}
