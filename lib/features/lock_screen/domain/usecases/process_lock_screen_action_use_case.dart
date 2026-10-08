import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/auth_failures.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../overrun_alert/domain/usecases/refresh_overrun_alert_schedule_use_case.dart';
import '../entities/lock_screen_timer_entity.dart';
import 'handle_lock_screen_action_use_case.dart';
import 'watch_lock_screen_timer_use_case.dart';

/// Lock screen button action received while the app is closed (background
/// entrypoint). Only acts with the user's session restored and answers what
/// the lock screen must show afterwards — `null` when the timer is gone
/// (confirmed stop, no "undo"). After an applied action it also rebuilds the
/// overrun alert series: pause/stop cancel it, resume schedules it again.
@lazySingleton
class ProcessLockScreenActionUseCase
    implements UseCase<LockScreenTimerEntity?, HandleLockScreenActionParams> {
  const ProcessLockScreenActionUseCase(
    this._authRepository,
    this._handleAction,
    this._watchTimer,
    this._refreshOverrunAlerts,
  );

  final AuthRepository _authRepository;
  final HandleLockScreenActionUseCase _handleAction;
  final WatchLockScreenTimerUseCase _watchTimer;
  final RefreshOverrunAlertScheduleUseCase _refreshOverrunAlerts;

  @override
  Future<Either<Failure, LockScreenTimerEntity?>> call(
    HandleLockScreenActionParams params,
  ) async {
    // First emission = session restored from the device (or null).
    final user = await _authRepository.authState().first;
    if (user == null) return const Left(UnauthenticatedFailure());

    final acted = await _handleAction(params);
    final failure = acted.getLeft().toNullable();
    if (failure != null) return Left(failure);

    // Runs in parallel with the reply read (no second wait on top of the 20 s
    // limit) and never throws, so a failure here does not change the reply.
    final refreshed = _refreshOverrunAlerts(const NoParams());
    final timer = await _watchTimer(const NoParams()).first;
    await refreshed; // the engine only replies after scheduling/cancelling
    return timer;
  }
}
