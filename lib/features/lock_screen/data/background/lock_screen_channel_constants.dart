/// Protocol of the lock screen background channel.
///
/// The channel name and the entrypoint name (`lockScreenActionMain`, in
/// `lib/main.dart`) are a contract with `android/` and `ios/`: changing them
/// here requires changing there.
abstract final class LockScreenChannelConstants {
  static const channelName = 'br.com.tekton.meutempo/lock_screen_action';

  /// Below the time Android (foreground service) and iPhone (App Intent) give
  /// to background work.
  static const actionTimeout = Duration(seconds: 20);
}

/// Keys of the `handleAction` payload (native → Dart).
abstract final class LockScreenActionPayloadKeys {
  static const action = 'action';
  static const targetId = 'targetId';
}

/// Keys of the `handleAction` reply (Dart → native).
abstract final class LockScreenReplyKeys {
  static const reply = 'reply';
  static const timer = 'timer';
}

/// Keys of the `timer` map sent to the native side.
abstract final class LockScreenTimerPayloadKeys {
  static const targetId = 'targetId';
  static const targetType = 'targetType';
  static const title = 'title';
  static const listName = 'listName';
  static const status = 'status';
  static const clockBaseEpochMillis = 'clockBaseEpochMillis';
  static const elapsedMillis = 'elapsedMillis';
  static const actions = 'actions';
  static const stopConfirmationWindowMillis = 'stopConfirmationWindowMillis';
}
