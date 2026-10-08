import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/lock_screen_timer_entity.dart';
import '../gateways/lock_screen_timer_gateway.dart';

class SyncLockScreenTimerParams extends Equatable {
  const SyncLockScreenTimerParams({required this.timer});

  /// What must be on screen now; `null` = nothing (stopped, no timer or
  /// signed out).
  final LockScreenTimerEntity? timer;

  @override
  List<Object?> get props => [timer];
}

/// Makes the lock screen and the notification shade match the real timer:
/// with a timer (running or paused) → show/update; without → remove (rule
/// "Stopped: disappears from the lock screen and the shade"). Only one shows
/// at a time: showing another target replaces the previous one (gateway
/// contract). Rule "permission asked on the first start": before showing a
/// **running** timer, if the permission was never asked, asks and waits for the
/// answer. A failure reading or asking never blocks the `show` (the service
/// works even when denied; only the notification stays hidden).
@lazySingleton
class SyncLockScreenTimerUseCase
    implements UseCase<Unit, SyncLockScreenTimerParams> {
  const SyncLockScreenTimerUseCase(this._gateway);

  final LockScreenTimerGateway _gateway;

  @override
  Future<Either<Failure, Unit>> call(SyncLockScreenTimerParams params) async {
    final timer = params.timer;
    if (timer == null) return _gateway.clear();
    if (timer.isRunning) {
      final status = await _gateway.getPermissionStatus();
      if (status.getRight().toNullable()?.shouldRequest ?? false) {
        await _gateway.requestPermission();
      }
    }
    return _gateway.show(timer);
  }
}
