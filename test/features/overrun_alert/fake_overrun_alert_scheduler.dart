import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/overrun_alert/domain/entities/overrun_alert_entity.dart';
import 'package:meu_tempo/features/overrun_alert/domain/entities/overrun_alert_plan_entity.dart';
import 'package:meu_tempo/features/overrun_alert/domain/gateways/overrun_alert_scheduler.dart';

/// Fake scheduler: records, in order, what the app asked it to do.
class FakeOverrunAlertScheduler implements OverrunAlertScheduler {
  /// One entry per call: the plan on `schedule`, `null` on `cancel`.
  final calls = <OverrunAlertPlanEntity?>[];

  Either<Failure, Unit> scheduleResult = const Right(unit);
  Either<Failure, Unit> cancelResult = const Right(unit);

  final _alerts = StreamController<OverrunAlertEntity>.broadcast();

  /// Simulates an alert firing.
  void fire(OverrunAlertEntity alert) => _alerts.add(alert);

  @override
  Future<Either<Failure, Unit>> schedule(OverrunAlertPlanEntity plan) async {
    calls.add(plan);
    return scheduleResult;
  }

  @override
  Future<Either<Failure, Unit>> cancel() async {
    calls.add(null);
    return cancelResult;
  }

  @override
  Stream<OverrunAlertEntity> watchAlerts() => _alerts.stream;

  Future<void> dispose() => _alerts.close();
}
