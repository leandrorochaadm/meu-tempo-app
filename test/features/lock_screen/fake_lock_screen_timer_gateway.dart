import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_permission_status_enum.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_tap_entity.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_timer_entity.dart';
import 'package:meu_tempo/features/lock_screen/domain/gateways/lock_screen_timer_gateway.dart';

/// Fake gateway: records, in order, what the app asked the "native side".
class FakeLockScreenTimerGateway implements LockScreenTimerGateway {
  /// One entry per call: the entity on `show`, `null` on `clear`.
  final pushes = <LockScreenTimerEntity?>[];

  /// Result returned by `show` (simulates the system refusing).
  Either<Failure, Unit> showResult = const Right(unit);

  /// Result returned by `clear`.
  Either<Failure, Unit> clearResult = const Right(unit);

  @override
  Future<Either<Failure, Unit>> show(LockScreenTimerEntity timer) async {
    pushes.add(timer);
    return showResult;
  }

  @override
  Future<Either<Failure, Unit>> clear() async {
    pushes.add(null);
    return clearResult;
  }

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
