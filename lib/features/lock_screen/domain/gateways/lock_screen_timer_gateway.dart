import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/lock_screen_permission_status_enum.dart';
import '../entities/lock_screen_tap_entity.dart';
import '../entities/lock_screen_timer_entity.dart';

/// Platform contract for the lock screen timer (Android foreground service,
/// iPhone Live Activity, empty on web). It only draws and relays: what to show
/// and which buttons come ready in [LockScreenTimerEntity].
abstract class LockScreenTimerGateway {
  /// Shows or updates the timer. Calling again with another target swaps it.
  Future<Either<Failure, Unit>> show(LockScreenTimerEntity timer);

  /// Removes the timer from the lock screen. No-op when nothing is showing.
  Future<Either<Failure, Unit>> clear();

  Future<Either<Failure, LockScreenPermissionStatusEnum>> getPermissionStatus();

  /// Opens the phone settings where the user turns notifications on.
  Future<Either<Failure, Unit>> openNotificationSettings();

  /// Taps on the timer outside the buttons.
  Stream<LockScreenTapEntity> watchTaps();
}
