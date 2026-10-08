/// Business constants of the overrun alert.
class OverrunAlertRules {
  const OverrunAlertRules._();

  /// After the first overrun alert, repeats at this interval until the timer
  /// is paused or stopped.
  static const Duration overrunRepeatInterval = Duration(hours: 1);
}
