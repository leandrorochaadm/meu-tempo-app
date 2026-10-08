import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/overrun_alert_entity.dart';
import '../entities/overrun_alert_plan_entity.dart';

/// Platform contract for the overrun alerts. No rule here: it schedules the
/// ready-made series, cancels it and exposes the alerts the app shows.
abstract class OverrunAlertScheduler {
  /// Schedules (or replaces) the series of the current timer. A plan equal to
  /// the one already scheduled restarts nothing.
  Future<Either<Failure, Unit>> schedule(OverrunAlertPlanEntity plan);

  /// Cancels every pending alert (paused, stopped, switched target, signed out).
  Future<Either<Failure, Unit>> cancel();

  /// Alerts the app shows inside the open screen. On the web: every firing.
  Stream<OverrunAlertEntity> watchAlerts();
}
