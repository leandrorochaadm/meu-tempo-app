import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../task/domain/entities/active_timer_entity.dart';
import '../../../task/domain/entities/task_entity.dart';
import '../../../task/domain/repositories/task_repository.dart';
import '../../../task/domain/repositories/timer_repository.dart';
import '../entities/overrun_alert_plan_entity.dart';
import 'plan_overrun_alerts_use_case.dart';

/// Stream of the current overrun series: crosses the active timer with the
/// user's tasks and applies [PlanOverrunAlertsUseCase] on every change.
///
/// Waits for both streams before emitting. A failure in either → `Left`.
/// Equal consecutive emissions are dropped, so an unrelated task change does
/// not reschedule anything.
@lazySingleton
class WatchOverrunAlertPlanUseCase
    implements
        StreamUseCase<Either<Failure, OverrunAlertPlanEntity?>, NoParams> {
  const WatchOverrunAlertPlanUseCase(
    this._timerRepository,
    this._taskRepository,
    this._planOverrunAlerts,
  );

  final TimerRepository _timerRepository;
  final TaskRepository _taskRepository;
  final PlanOverrunAlertsUseCase _planOverrunAlerts;

  @override
  Stream<Either<Failure, OverrunAlertPlanEntity?>> call(NoParams params) {
    final subscriptions = <StreamSubscription<Object?>>[];
    Either<Failure, ActiveTimerEntity?>? timer;
    Either<Failure, List<TaskEntity>>? tasks;
    late final StreamController<Either<Failure, OverrunAlertPlanEntity?>>
    controller;

    void recompute() {
      final result = _combine(timer, tasks);
      if (result != null) controller.add(result);
    }

    controller = StreamController<Either<Failure, OverrunAlertPlanEntity?>>(
      onListen: () {
        subscriptions.addAll([
          _timerRepository.watchActive().listen((value) {
            timer = value;
            recompute();
          }, onError: controller.addError),
          // Includes done tasks: a completed task with a running timer still
          // gets the reminder to stop.
          _taskRepository.watchTasks(includeDone: true).listen((value) {
            tasks = value;
            recompute();
          }, onError: controller.addError),
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

  /// `null` = a stream is still missing (emit nothing).
  Either<Failure, OverrunAlertPlanEntity?>? _combine(
    Either<Failure, ActiveTimerEntity?>? timer,
    Either<Failure, List<TaskEntity>>? tasks,
  ) {
    if (timer == null || tasks == null) return null;
    final timerFailure = timer.getLeft().toNullable();
    if (timerFailure != null) return Left(timerFailure);
    final tasksFailure = tasks.getLeft().toNullable();
    if (tasksFailure != null) return Left(tasksFailure);
    return Right(
      _planOverrunAlerts(
        timer.getRight().toNullable(),
        tasks.getRight().toNullable() ?? const <TaskEntity>[],
      ),
    );
  }
}
