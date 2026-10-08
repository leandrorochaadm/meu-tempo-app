import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/overrun_alert/domain/entities/overrun_alert_entity.dart';
import 'package:meu_tempo/features/overrun_alert/domain/entities/overrun_alert_plan_entity.dart';

void main() {
  final at = DateTime(2026, 10, 7, 10, 30);
  final alert = OverrunAlertEntity(
    targetId: 't1',
    title: 'Tela de login',
    alertAt: at,
  );
  OverrunAlertPlanEntity planFor(String id) => OverrunAlertPlanEntity(
    targetId: id,
    title: 'x',
    firstAlertAt: at,
    repeatInterval: const Duration(hours: 1),
  );

  test('should still apply when plan has the same target', () {
    expect(alert.stillAppliesTo(planFor('t1')), isTrue);
  });

  test('should not apply when plan is null', () {
    expect(alert.stillAppliesTo(null), isFalse);
  });

  test('should not apply when plan is for another target', () {
    expect(alert.stillAppliesTo(planFor('t2')), isFalse);
  });
}
