import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/overrun_alert_plan_entity.dart';
import 'sync_overrun_alert_schedule_use_case.dart';
import 'watch_overrun_alert_plan_use_case.dart';

/// Rebuilds the overrun alert series from the current timer, once. Used
/// outside the open app (lock screen action): pause or stop cancels, resume
/// schedules again. Never throws: a plan read error becomes `Left` and leaves
/// the series untouched.
@lazySingleton
class RefreshOverrunAlertScheduleUseCase implements UseCase<Unit, NoParams> {
  const RefreshOverrunAlertScheduleUseCase(this._watchPlan, this._syncSchedule);

  final WatchOverrunAlertPlanUseCase _watchPlan;
  final SyncOverrunAlertScheduleUseCase _syncSchedule;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    final Either<Failure, OverrunAlertPlanEntity?> current;
    try {
      current = await _watchPlan(const NoParams()).first;
    } catch (_) {
      // Stream with error, or closed without emitting (`StateError` of `.first`).
      return const Left(ServerFailure());
    }
    return current.match(
      (failure) async => Left(failure), // plan not read: leave the series alone
      (plan) => _syncSchedule(SyncOverrunAlertScheduleParams(plan: plan)),
    );
  }
}
