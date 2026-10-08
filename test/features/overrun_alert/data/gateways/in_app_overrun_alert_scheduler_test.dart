import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/overrun_alert/data/gateways/in_app_overrun_alert_scheduler.dart';
import 'package:meu_tempo/features/overrun_alert/domain/entities/overrun_alert_entity.dart';
import 'package:meu_tempo/features/overrun_alert/domain/entities/overrun_alert_plan_entity.dart';

void main() {
  final t0 = DateTime(2026, 10, 7, 10);
  final plan = OverrunAlertPlanEntity(
    targetId: 't1',
    title: 'Tela de login',
    firstAlertAt: DateTime(2026, 10, 7, 10, 30),
    repeatInterval: const Duration(hours: 1),
  );

  /// Runs [body] under fakeAsync with a scheduler on the fake clock.
  void run(
    void Function(
      FakeAsync async,
      InAppOverrunAlertScheduler scheduler,
      List<OverrunAlertEntity> alerts,
    )
    body,
  ) {
    fakeAsync((async) {
      final clock = async.getClock(t0);
      final scheduler = InAppOverrunAlertScheduler(now: clock.now);
      final alerts = <OverrunAlertEntity>[];
      scheduler.watchAlerts().listen(alerts.add);
      body(async, scheduler, alerts);
    });
  }

  test('should not alert before the estimate', () {
    run((async, scheduler, alerts) {
      scheduler.schedule(plan);
      async.elapse(const Duration(minutes: 29, seconds: 59));
      expect(alerts, isEmpty);
    });
  });

  test('should alert at the estimate and every hour after', () {
    run((async, scheduler, alerts) {
      scheduler.schedule(plan);
      async.elapse(const Duration(minutes: 90));
      expect(alerts.map((a) => a.alertAt), [
        DateTime(2026, 10, 7, 10, 30),
        DateTime(2026, 10, 7, 11, 30),
      ]);
      expect(alerts.first.title, 'Tela de login');
    });
  });

  test('should alert immediately when scheduled exactly at the alert time', () {
    run((async, scheduler, alerts) {
      async.elapse(const Duration(minutes: 30));
      scheduler.schedule(plan);
      async.elapse(Duration.zero);
      expect(alerts, hasLength(1));
    });
  });

  test('should start from the next hourly alert when opened late', () {
    run((async, scheduler, alerts) {
      async.elapse(const Duration(hours: 2, minutes: 10));
      scheduler.schedule(plan);
      async.elapse(const Duration(minutes: 19));
      expect(alerts, isEmpty);
      async.elapse(const Duration(minutes: 1));
      expect(alerts.single.alertAt, DateTime(2026, 10, 7, 12, 30));
    });
  });

  test('should stop alerting after cancel', () {
    run((async, scheduler, alerts) {
      scheduler.schedule(plan);
      async.elapse(const Duration(minutes: 31));
      expect(alerts, hasLength(1));
      scheduler.cancel();
      async.elapse(const Duration(hours: 3));
      expect(alerts, hasLength(1));
    });
  });

  test('should replace the series when a new plan is scheduled', () {
    run((async, scheduler, alerts) {
      scheduler.schedule(plan);
      scheduler.schedule(
        OverrunAlertPlanEntity(
          targetId: 't2',
          title: 'Outra',
          firstAlertAt: DateTime(2026, 10, 7, 10, 45),
          repeatInterval: const Duration(hours: 1),
        ),
      );
      async.elapse(const Duration(minutes: 50));
      expect(alerts.map((a) => a.targetId), ['t2']);
    });
  });

  test('should not restart when the same plan is scheduled again', () {
    run((async, scheduler, alerts) {
      scheduler.schedule(plan);
      async.elapse(const Duration(minutes: 20));
      scheduler.schedule(plan);
      async.elapse(const Duration(minutes: 11));
      expect(alerts, hasLength(1));
    });
  });
}
