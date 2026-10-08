/// State of the phone notification permission, which decides whether the
/// timer can show on the lock screen.
enum LockScreenPermissionStatusEnum {
  /// Notifications allowed: the timer shows.
  granted('granted'),

  /// User denied or turned off in settings: the timer does not show.
  denied('denied'),

  /// The app has not asked for the permission yet; the first start asks. Only
  /// Android reports it; the iPhone returns `granted` or `denied`.
  notRequested('not_requested'),

  /// Platform without a lock screen (browser): nothing to ask for.
  unsupported('unsupported');

  const LockScreenPermissionStatusEnum(this.apiValue);

  /// Spelling returned by the native side.
  final String apiValue;

  /// Only **denied** notifications block the timer (the app then shows the
  /// permission banner). In the browser the banner never shows.
  bool get blocksLockScreen => this == denied;

  /// Never asked: the first running timer asks before showing.
  bool get shouldRequest => this == notRequested;

  /// Unknown or missing value returns [unsupported]: without certainty that
  /// notifications are denied, the app does not nag with the banner.
  static LockScreenPermissionStatusEnum fromApi(String? raw) {
    for (final status in values) {
      if (status.apiValue == raw) return status;
    }
    return unsupported;
  }
}
