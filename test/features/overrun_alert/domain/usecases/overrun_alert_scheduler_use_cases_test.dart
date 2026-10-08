import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/overrun_alert/domain/entities/overrun_alert_entity.dart';
import 'package:meu_tempo/features/overrun_alert/domain/entities/overrun_alert_plan_entity.dart';
import 'package:meu_tempo/features/overrun_alert/domain/usecases/sync_overrun_alert_schedule_use_case.dart';
import 'package:meu_tempo/features/overrun_alert/domain/usecases/watch_overrun_alerts_use_case.dart';

import '../../fake_overrun_alert_scheduler.dart';

void main() {
  late FakeOverrunAlertScheduler scheduler;
  final at = DateTime(2026, 10, 7, 10, 30);
  final plan = OverrunAlertPlanEntity(
    targetId: 't1',
    title: 'T',
    firstAlertAt: at,
    repeatInterval: const Duration(hours: 1),
  );

  setUp(() => scheduler = FakeOverrunAlertScheduler());
  tearDown(() => scheduler.dispose());

  test('sync should schedule when plan exists', () async {
    final result = await SyncOverrunAlertScheduleUseCase(scheduler)(
      SyncOverrunAlertScheduleParams(plan: plan),
    );
    expect(result.isRight(), isTrue);
    expect(scheduler.calls, [plan]);
  });

  test('sync should cancel when plan is null', () async {
    await SyncOverrunAlertScheduleUseCase(scheduler)(
      const SyncOverrunAlertScheduleParams(plan: null),
    );
    expect(scheduler.calls, [null]);
  });

  test('sync should return Left when scheduler fails', () async {
    scheduler.scheduleResult = const Left(ServerFailure());
    final result = await SyncOverrunAlertScheduleUseCase(scheduler)(
      SyncOverrunAlertScheduleParams(plan: plan),
    );
    expect(result.isLeft(), isTrue);
  });

  test('watch alerts should forward scheduler alerts', () async {
    final alert = OverrunAlertEntity(targetId: 't1', title: 'T', alertAt: at);
    final future = WatchOverrunAlertsUseCase(scheduler)(const NoParams()).first;
    scheduler.fire(alert);
    expect(await future, alert);
  });
}
