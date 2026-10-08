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
/// contract).
@lazySingleton
class SyncLockScreenTimerUseCase
    implements UseCase<Unit, SyncLockScreenTimerParams> {
  const SyncLockScreenTimerUseCase(this._gateway);

  final LockScreenTimerGateway _gateway;

  @override
  Future<Either<Failure, Unit>> call(SyncLockScreenTimerParams params) {
    final timer = params.timer;
    return timer == null ? _gateway.clear() : _gateway.show(timer);
  }
}
