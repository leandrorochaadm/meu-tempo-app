import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../task/domain/usecases/finish_timer_use_case.dart';
import '../../../task/domain/usecases/pause_timer_use_case.dart';
import '../../../task/domain/usecases/resume_timer_use_case.dart';
import '../entities/lock_screen_action_enum.dart';

class HandleLockScreenActionParams extends Equatable {
  const HandleLockScreenActionParams({
    required this.action,
    required this.targetId,
    required this.now,
  });

  final LockScreenActionEnum action;

  /// Target the lock screen was showing when the button was tapped. If the
  /// active timer is already another one, the destination UseCase no-ops.
  final String targetId;
  final DateTime now;

  @override
  List<Object?> get props => [action, targetId, now];
}

/// Runs a lock screen button action, the same for task and appointment:
/// pause → [PauseTimerUseCase]; resume → [ResumeTimerUseCase]; confirmed stop
/// → [FinishTimerUseCase] (stops and completes). Only dispatches: the right
/// target and idempotency live in the destination UseCases.
@lazySingleton
class HandleLockScreenActionUseCase
    implements UseCase<Unit, HandleLockScreenActionParams> {
  const HandleLockScreenActionUseCase(
    this._pauseTimer,
    this._resumeTimer,
    this._finishTimer,
  );

  final PauseTimerUseCase _pauseTimer;
  final ResumeTimerUseCase _resumeTimer;
  final FinishTimerUseCase _finishTimer;

  @override
  Future<Either<Failure, Unit>> call(HandleLockScreenActionParams params) =>
      switch (params.action) {
        LockScreenActionEnum.pause => _pauseTimer(
          PauseTimerParams(targetId: params.targetId, now: params.now),
        ),
        LockScreenActionEnum.resume => _resumeTimer(
          ResumeTimerParams(targetId: params.targetId, now: params.now),
        ),
        LockScreenActionEnum.stopConfirmed => _finishTimer(
          FinishTimerParams(targetId: params.targetId, now: params.now),
        ),
      };
}
