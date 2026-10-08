import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/overrun_alert_entity.dart';
import '../../domain/entities/overrun_alert_plan_entity.dart';
import '../../domain/gateways/overrun_alert_scheduler.dart';

/// "Inside the app" scheduler: a `dart:async` [Timer], no rules; the times
/// come from the plan. Works on the web and on the phone while the app is
/// open. Never fails.
class InAppOverrunAlertScheduler implements OverrunAlertScheduler {
  InAppOverrunAlertScheduler({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final _alerts = StreamController<OverrunAlertEntity>.broadcast();
  Timer? _timer;
  OverrunAlertPlanEntity? _plan;

  @override
  Future<Either<Failure, Unit>> schedule(OverrunAlertPlanEntity plan) async {
    // Same plan again: do not restart.
    if (plan == _plan) return const Right(unit);
    _timer?.cancel();
    _plan = plan;
    _arm(plan, plan.nextAlertAt(_now()));
    return const Right(unit);
  }

  void _arm(OverrunAlertPlanEntity plan, DateTime at) {
    final delay = at.difference(_now());
    _timer = Timer(delay.isNegative ? Duration.zero : delay, () {
      _alerts.add(
        OverrunAlertEntity(
          targetId: plan.targetId,
          title: plan.title,
          alertAt: at,
        ),
      );
      // A timer can fire a few ms before `at` on the wall clock; never ask
      // for the alert after a moment earlier than the one that just fired.
      final now = _now();
      _arm(plan, plan.alertAfter(now.isBefore(at) ? at : now));
    });
  }

  @override
  Future<Either<Failure, Unit>> cancel() async {
    _timer?.cancel();
    _timer = null;
    _plan = null;
    return const Right(unit);
  }

  @override
  Stream<OverrunAlertEntity> watchAlerts() => _alerts.stream;
}
