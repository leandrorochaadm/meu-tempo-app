import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/lock_screen_permission_status_enum.dart';
import '../../domain/entities/lock_screen_tap_entity.dart';
import '../../domain/entities/lock_screen_timer_entity.dart';
import '../../domain/gateways/lock_screen_timer_gateway.dart';

/// Empty lock screen timer implementation. Final on web (no lock screen);
/// until the native steps it also serves Android and iPhone. Never fails.
class NoopLockScreenTimerGateway implements LockScreenTimerGateway {
  const NoopLockScreenTimerGateway();

  @override
  Future<Either<Failure, Unit>> show(LockScreenTimerEntity timer) async =>
      const Right(unit);

  @override
  Future<Either<Failure, Unit>> clear() async => const Right(unit);

  @override
  Future<Either<Failure, LockScreenPermissionStatusEnum>>
  getPermissionStatus() async =>
      const Right(LockScreenPermissionStatusEnum.unsupported);

  @override
  Future<Either<Failure, Unit>> openNotificationSettings() async =>
      const Right(unit);

  @override
  Stream<LockScreenTapEntity> watchTaps() => const Stream.empty();
}
