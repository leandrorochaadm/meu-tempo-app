import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../appointment/domain/entities/appointment_entity.dart';
import '../../../appointment/domain/repositories/appointment_repository.dart';
import '../../../list/domain/entities/task_list_entity.dart';
import '../../../list/domain/repositories/task_list_repository.dart';
import '../../../task/domain/entities/active_timer_entity.dart';
import '../../../task/domain/entities/task_entity.dart';
import '../../../task/domain/entities/timer_target_type_enum.dart';
import '../../../task/domain/repositories/task_repository.dart';
import '../../../task/domain/repositories/timer_repository.dart';
import '../entities/lock_screen_timer_entity.dart';
import '../services/lock_screen_timer_resolver.dart';

/// Stream of what the lock screen must show: crosses the active timer with
/// the user's tasks, appointments and lists.
///
/// - No timer → `Right(null)`, emitted right away.
/// - Running or paused → `Right(entity)` once the stream of the target's type
///   (tasks **or** appointments) and the lists have arrived.
/// - Target not found → `Right(null)`.
/// - Failure in the timer, the target's stream or the lists → `Left`. A
///   failure in the stream the current target does not use is ignored.
///
/// Starting another target goes through a transient `Right(null)` (the
/// previous timer is claimed before the new one is set). Equal consecutive
/// emissions are dropped. For a one-off read, use `.first`.
@lazySingleton
class WatchLockScreenTimerUseCase
    implements
        StreamUseCase<Either<Failure, LockScreenTimerEntity?>, NoParams> {
  const WatchLockScreenTimerUseCase(
    this._timerRepository,
    this._taskRepository,
    this._appointmentRepository,
    this._taskListRepository,
  );

  final TimerRepository _timerRepository;
  final TaskRepository _taskRepository;
  final AppointmentRepository _appointmentRepository;
  final TaskListRepository _taskListRepository;

  @override
  Stream<Either<Failure, LockScreenTimerEntity?>> call(NoParams params) {
    final subscriptions = <StreamSubscription<Object?>>[];
    Either<Failure, ActiveTimerEntity?>? timer;
    Either<Failure, List<TaskEntity>>? tasks;
    Either<Failure, List<AppointmentEntity>>? appointments;
    Either<Failure, List<TaskListEntity>>? lists;
    late final StreamController<Either<Failure, LockScreenTimerEntity?>>
        controller;

    void recompute() {
      final result = _combine(timer, tasks, appointments, lists);
      if (result != null) controller.add(result);
    }

    controller = StreamController<Either<Failure, LockScreenTimerEntity?>>(
      onListen: () {
        subscriptions.addAll([
          _timerRepository.watchActive().listen(
            (value) {
              timer = value;
              recompute();
            },
            onError: controller.addError,
          ),
          // Includes done tasks: the target must be found even if it was
          // completed from the app.
          _taskRepository.watchTasks(includeDone: true).listen(
            (value) {
              tasks = value;
              recompute();
            },
            onError: controller.addError,
          ),
          _appointmentRepository.watchAll().listen(
            (value) {
              appointments = value;
              recompute();
            },
            onError: controller.addError,
          ),
          _taskListRepository.watchLists().listen(
            (value) {
              lists = value;
              recompute();
            },
            onError: controller.addError,
          ),
        ]);
      },
      onPause: () {
        for (final subscription in subscriptions) {
          subscription.pause();
        }
      },
      onResume: () {
        for (final subscription in subscriptions) {
          subscription.resume();
        }
      },
      onCancel: () => Future.wait(subscriptions.map((s) => s.cancel())),
    );
    return controller.stream.distinct();
  }

  /// Decides what to emit with what has arrived. `null` = a required stream
  /// is still missing (emit nothing).
  static Either<Failure, LockScreenTimerEntity?>? _combine(
    Either<Failure, ActiveTimerEntity?>? timer,
    Either<Failure, List<TaskEntity>>? tasks,
    Either<Failure, List<AppointmentEntity>>? appointments,
    Either<Failure, List<TaskListEntity>>? lists,
  ) {
    if (timer == null) return null;
    final timerFailure = timer.getLeft().toNullable();
    if (timerFailure != null) return Left(timerFailure);
    final active = timer.getRight().toNullable();
    if (active == null) return const Right(null);

    if (lists == null) return null;
    final listsFailure = lists.getLeft().toNullable();
    if (listsFailure != null) return Left(listsFailure);
    final allLists = lists.getRight().toNullable() ?? const <TaskListEntity>[];

    switch (active.targetType) {
      case TimerTargetTypeEnum.task:
        if (tasks == null) return null;
        return tasks.map<LockScreenTimerEntity?>(
          (all) => LockScreenTimerResolver.fromTask(active, all, allLists),
        );
      case TimerTargetTypeEnum.appointment:
        if (appointments == null) return null;
        return appointments.map<LockScreenTimerEntity?>(
          (all) =>
              LockScreenTimerResolver.fromAppointment(active, all, allLists),
        );
    }
  }
}
