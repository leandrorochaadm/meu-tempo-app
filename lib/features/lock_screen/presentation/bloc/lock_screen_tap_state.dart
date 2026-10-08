part of 'lock_screen_tap_bloc.dart';

sealed class LockScreenTapState extends Equatable {
  const LockScreenTapState();

  @override
  List<Object?> get props => const [];
}

/// No tap waiting for navigation.
class LockScreenTapIdle extends LockScreenTapState {
  const LockScreenTapIdle();
}

/// Tap waiting for the screen to open the target. Kept while there is no
/// signed-in screen (app opened by the tap, login still resolving).
class LockScreenTapPending extends LockScreenTapState {
  const LockScreenTapPending(this.tap);

  final LockScreenTapEntity tap;

  @override
  List<Object?> get props => [tap];
}
