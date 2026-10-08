import '../../../appointment/domain/entities/appointment_entity.dart';
import '../../../list/domain/entities/task_list_entity.dart';
import '../../../task/domain/entities/active_timer_entity.dart';
import '../../../task/domain/entities/task_entity.dart';
import '../entities/lock_screen_timer_entity.dart';

/// Builds what the lock screen shows from the active timer and its target
/// (task or appointment), same shape for both. Pure and synchronous.
class LockScreenTimerResolver {
  const LockScreenTimerResolver._();

  /// `null` when the task is not in [tasks] (deleted or not loaded yet).
  static LockScreenTimerEntity? fromTask(
    ActiveTimerEntity active,
    List<TaskEntity> tasks,
    List<TaskListEntity> lists,
  ) {
    for (final task in tasks) {
      if (task.id == active.targetId) {
        return _build(
          active,
          title: task.title,
          listId: task.listId,
          spentMinutes: task.spentMinutes,
          lists: lists,
        );
      }
    }
    return null;
  }

  /// `null` when the appointment is not in [appointments].
  static LockScreenTimerEntity? fromAppointment(
    ActiveTimerEntity active,
    List<AppointmentEntity> appointments,
    List<TaskListEntity> lists,
  ) {
    for (final appointment in appointments) {
      if (appointment.id == active.targetId) {
        return _build(
          active,
          title: appointment.title,
          listId: appointment.listId,
          spentMinutes: appointment.spentMinutes,
          lists: lists,
        );
      }
    }
    return null;
  }

  /// The list comes from the **target**, not from the `listId` stored at
  /// start: if the task changed list while running, the current one shows.
  static LockScreenTimerEntity _build(
    ActiveTimerEntity active, {
    required String title,
    required String listId,
    required int spentMinutes,
    required List<TaskListEntity> lists,
  }) => LockScreenTimerEntity(
    targetId: active.targetId,
    targetType: active.targetType,
    title: title,
    listName: _listName(listId, lists),
    status: active.status,
    spentMinutes: spentMinutes,
    sessionStartedAt: active.startedAt,
  );

  /// Empty when the list is not found.
  static String _listName(String listId, List<TaskListEntity> lists) {
    for (final list in lists) {
      if (list.id == listId) return list.name;
    }
    return '';
  }
}
