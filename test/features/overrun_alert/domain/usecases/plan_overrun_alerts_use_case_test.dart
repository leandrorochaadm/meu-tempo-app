import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/overrun_alert/domain/overrun_alert_rules.dart';
import 'package:meu_tempo/features/overrun_alert/domain/usecases/plan_overrun_alerts_use_case.dart';
import 'package:meu_tempo/features/task/domain/entities/active_timer_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';

void main() {
  const useCase = PlanOverrunAlertsUseCase();
  final t0 = DateTime(2026, 10, 7, 10);

  TaskEntity task({int? estimated = 30, int spent = 0}) => TaskEntity(
    id: 't1',
    title: 'Tela de login',
    listId: 'l1',
    createdAt: t0,
    estimatedMinutes: estimated,
    spentMinutes: spent,
  );

  ActiveTimerEntity timer({
    DateTime? startedAt,
    TimerStatusEnum status = TimerStatusEnum.running,
    TimerTargetTypeEnum type = TimerTargetTypeEnum.task,
  }) => ActiveTimerEntity(
    targetId: 't1',
    targetType: type,
    listId: 'l1',
    startedAt: startedAt ?? t0,
    status: status,
  );

  test('should plan first alert when spent reaches estimate', () {
    final plan = useCase(timer(), [task()])!;
    expect(plan.firstAlertAt, DateTime(2026, 10, 7, 10, 30));
    expect(plan.repeatInterval, OverrunAlertRules.overrunRepeatInterval);
    expect(plan.title, 'Tela de login');
    expect(plan.targetId, 't1');
  });

  test('should alert exactly at the estimate', () {
    final plan = useCase(timer(), [task(spent: 10)])!;
    expect(plan.firstAlertAt, DateTime(2026, 10, 7, 10, 20));
    expect(
      plan.nextAlertAt(DateTime(2026, 10, 7, 10, 20)),
      DateTime(2026, 10, 7, 10, 20),
    );
  });

  test('should alert 1 h after start when already overrun at start', () {
    final plan = useCase(timer(), [task(spent: 45)])!;
    expect(plan.firstAlertAt, DateTime(2026, 10, 7, 11));
  });

  test('should alert 1 h after start when spent equals estimate at start', () {
    final plan = useCase(timer(), [task(spent: 30)])!;
    expect(plan.firstAlertAt, DateTime(2026, 10, 7, 11));
  });

  test('should count from resume after a pause', () {
    final plan = useCase(timer(startedAt: DateTime(2026, 10, 7, 14)), [
      task(spent: 25),
    ])!;
    expect(plan.firstAlertAt, DateTime(2026, 10, 7, 14, 5));
  });

  test('should return null when timer is paused', () {
    expect(useCase(timer(status: TimerStatusEnum.paused), [task()]), isNull);
  });

  test('should return null when there is no timer', () {
    expect(useCase(null, [task()]), isNull);
  });

  test('should return null for appointment', () {
    expect(
      useCase(timer(type: TimerTargetTypeEnum.appointment), [task()]),
      isNull,
    );
  });

  test('should return null when task has no estimate', () {
    expect(useCase(timer(), [task(estimated: null)]), isNull);
    expect(useCase(timer(), [task(estimated: 0)]), isNull);
  });

  test('should return null when task is not found', () {
    expect(useCase(timer(), const []), isNull);
  });
}
