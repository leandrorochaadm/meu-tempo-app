import 'package:injectable/injectable.dart';

import '../../../task/domain/entities/active_timer_entity.dart';
import '../../../task/domain/entities/task_entity.dart';
import '../../../task/domain/entities/timer_target_type_enum.dart';
import '../entities/overrun_alert_plan_entity.dart';
import '../overrun_alert_rules.dart';

/// Overrun rule: given the timer and the tasks, returns the series of alerts
/// or `null` (no timer, paused, appointment, no estimate, target not found).
/// "Now" is not an input: the plan does not change with the clock (see
/// [OverrunAlertPlanEntity.nextAlertAt]).
@lazySingleton
class PlanOverrunAlertsUseCase {
  const PlanOverrunAlertsUseCase();

  OverrunAlertPlanEntity? call(
    ActiveTimerEntity? active,
    List<TaskEntity> tasks,
  ) {
    // No timer or paused: time is not counting, no alert.
    if (active == null || !active.isRunning) return null;
    switch (active.targetType) {
      case TimerTargetTypeEnum.appointment:
        return null;
      case TimerTargetTypeEnum.task:
        break;
    }
    final task = _find(active.targetId, tasks);
    final estimated = task?.estimatedMinutes;
    if (task == null || estimated == null || estimated <= 0) return null;

    // Instant when the time spent (previous sessions + current) reaches the
    // estimate. `spentMinutes` does not include the current session.
    final reachesEstimateAt = active.startedAt.add(
      Duration(minutes: estimated - task.spentMinutes),
    );
    const interval = OverrunAlertRules.overrunRepeatInterval;
    // Already at/over the estimate when started or resumed: the first alert
    // comes one interval later (never at the instant of the start).
    final firstAlertAt = reachesEstimateAt.isAfter(active.startedAt)
        ? reachesEstimateAt
        : active.startedAt.add(interval);
    return OverrunAlertPlanEntity(
      targetId: task.id,
      title: task.title,
      firstAlertAt: firstAlertAt,
      repeatInterval: interval,
    );
  }

  static TaskEntity? _find(String id, List<TaskEntity> tasks) {
    for (final task in tasks) {
      if (task.id == id) return task;
    }
    return null;
  }
}
