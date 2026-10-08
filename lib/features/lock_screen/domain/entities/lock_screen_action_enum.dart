/// Action fired by a lock screen timer button. "Stop" only arrives here after
/// the second tap ("confirm"): the first tap is a visual state of the native
/// side, lasting `LockScreenRules.stopConfirmationWindow`.
enum LockScreenActionEnum {
  pause('pause'),
  resume('resume'),
  stopConfirmed('stop_confirmed');

  const LockScreenActionEnum(this.apiValue);

  /// Spelling exchanged with the native side.
  final String apiValue;

  /// Unknown or missing value returns `null`: the caller treats it as a
  /// logged no-op and never guesses an action, because "stop" completes the
  /// task.
  static LockScreenActionEnum? fromApi(String? raw) {
    for (final action in values) {
      if (action.apiValue == raw) return action;
    }
    return null;
  }
}
