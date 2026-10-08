import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/overrun_alert_plan_entity.dart';
import '../gateways/overrun_alert_scheduler.dart';

class SyncOverrunAlertScheduleParams extends Equatable {
  const SyncOverrunAlertScheduleParams({required this.plan});

  /// Series that must be pending now; `null` = none.
  final OverrunAlertPlanEntity? plan;

  @override
  List<Object?> get props => [plan];
}

/// Makes the pending alerts match the plan: with a plan → schedule; without
/// → cancel ("repeats until paused or stopped").
@lazySingleton
class SyncOverrunAlertScheduleUseCase
    implements UseCase<Unit, SyncOverrunAlertScheduleParams> {
  const SyncOverrunAlertScheduleUseCase(this._scheduler);

  final OverrunAlertScheduler _scheduler;

  @override
  Future<Either<Failure, Unit>> call(
    SyncOverrunAlertScheduleParams params,
  ) async {
    final plan = params.plan;
    if (plan == null) return _scheduler.cancel();
    return _scheduler.schedule(plan);
  }
}
