part of 'lock_screen_tap_bloc.dart';

sealed class LockScreenTapEvent extends Equatable {
  const LockScreenTapEvent();

  @override
  List<Object?> get props => const [];
}

/// App start: begins receiving taps on the timer.
class LockScreenTapStarted extends LockScreenTapEvent {
  const LockScreenTapStarted();
}

/// The screen already navigated to the target of [tap]: back to waiting.
class LockScreenTapHandled extends LockScreenTapEvent {
  const LockScreenTapHandled(this.tap);

  final LockScreenTapEntity tap;

  @override
  List<Object?> get props => [tap];
}

/// Internal: the native side delivered a tap.
class _LockScreenTapReceived extends LockScreenTapEvent {
  const _LockScreenTapReceived(this.tap);

  final LockScreenTapEntity tap;

  @override
  List<Object?> get props => [tap];
}
