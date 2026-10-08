/// Business constants of the lock screen timer.
class LockScreenRules {
  const LockScreenRules._();

  /// After the first tap on "stop", the button becomes "confirm" for this
  /// long; without a second tap it goes back to "stop" and nothing changes.
  static const Duration stopConfirmationWindow = Duration(seconds: 5);
}
