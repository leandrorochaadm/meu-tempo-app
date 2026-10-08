import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/lock_screen_permission_status_enum.dart';
import '../gateways/lock_screen_timer_gateway.dart';

/// Current state of the phone notification permission. Whether it blocks the
/// lock screen timer is decided by the enum itself
/// ([LockScreenPermissionStatusEnum.blocksLockScreen]).
@lazySingleton
class GetLockScreenPermissionStatusUseCase
    implements UseCase<LockScreenPermissionStatusEnum, NoParams> {
  const GetLockScreenPermissionStatusUseCase(this._gateway);

  final LockScreenTimerGateway _gateway;

  @override
  Future<Either<Failure, LockScreenPermissionStatusEnum>> call(
    NoParams params,
  ) =>
      _gateway.getPermissionStatus();
}
