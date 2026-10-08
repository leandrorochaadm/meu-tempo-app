import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/overrun_alert/domain/entities/overrun_alert_plan_entity.dart';

void main() {
  final first = DateTime(2026, 10, 7, 10, 30);
  final plan = OverrunAlertPlanEntity(
    targetId: 't1',
    title: 'Tela de login',
    firstAlertAt: first,
    repeatInterval: const Duration(hours: 1),
  );

  test('should return firstAlertAt when now is before it', () {
    expect(plan.nextAlertAt(DateTime(2026, 10, 7, 10)), first);
  });

  test('should return firstAlertAt when now is exactly it', () {
    expect(plan.nextAlertAt(first), first);
  });

  test('should return the next hourly alert when now is between alerts', () {
    expect(
      plan.nextAlertAt(DateTime(2026, 10, 7, 12, 10)),
      DateTime(2026, 10, 7, 12, 30),
    );
    expect(
      plan.nextAlertAt(DateTime(2026, 10, 7, 12, 40)),
      DateTime(2026, 10, 7, 13, 30),
    );
  });

  test('alertAfter should skip the alert at the same instant', () {
    expect(plan.alertAfter(first), DateTime(2026, 10, 7, 11, 30));
  });

  test('alertAfter should not replay missed alerts', () {
    expect(
      plan.alertAfter(DateTime(2026, 10, 7, 13, 5)),
      DateTime(2026, 10, 7, 13, 30),
    );
  });

  test('should be equal by value', () {
    final other = OverrunAlertPlanEntity(
      targetId: 't1',
      title: 'Tela de login',
      firstAlertAt: first,
      repeatInterval: const Duration(hours: 1),
    );
    expect(plan, other);
  });
}
