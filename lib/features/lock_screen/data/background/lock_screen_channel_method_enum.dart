/// Methods of the lock screen action channel.
enum LockScreenChannelMethodEnum {
  /// Dart → native: the handler is registered; the native side may send taps.
  backgroundReady('backgroundReady'),

  /// Dart → native: Firebase/DI failed to start; the native side goes back to
  /// the previous drawing and stops the engine.
  backgroundFailed('backgroundFailed'),

  /// Native → Dart: a button was tapped (`action` + `targetId`).
  handleAction('handleAction');

  const LockScreenChannelMethodEnum(this.apiValue);

  final String apiValue;

  /// Unknown or missing value returns `null`.
  static LockScreenChannelMethodEnum? fromApi(String? raw) {
    for (final method in values) {
      if (method.apiValue == raw) return method;
    }
    return null;
  }
}
