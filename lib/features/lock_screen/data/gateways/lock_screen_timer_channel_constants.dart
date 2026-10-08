/// Contract with `android/.../lockscreen/LockScreenContract.kt` and
/// `ios/MeuTempoLiveActivity/Shared/LockScreenContract.swift`: changing a
/// name here requires changing there.
abstract final class LockScreenTimerChannelConstants {
  static const methodChannelName = 'br.com.tekton.meutempo/lock_screen_timer';
  static const tapChannelName = 'br.com.tekton.meutempo/lock_screen_taps';

  /// Limit of the native calls (except `requestPermission`, which waits for the
  /// user): the sequential queue of the `LockScreenSyncBloc` never hangs.
  static const callTimeout = Duration(seconds: 5);
}
