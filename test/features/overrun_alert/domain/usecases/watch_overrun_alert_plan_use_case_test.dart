import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/overrun_alert/domain/entities/overrun_alert_plan_entity.dart';
import 'package:meu_tempo/features/overrun_alert/domain/usecases/plan_overrun_alerts_use_case.dart';
import 'package:meu_tempo/features/overrun_alert/domain/usecases/watch_overrun_alert_plan_use_case.dart';
import 'package:meu_tempo/features/task/domain/entities/active_timer_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart';
import 'package:meu_tempo/features/task/domain/repositories/timer_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockTimerRepo extends Mock implements TimerRepository {}

class _MockTaskRepo extends Mock implements TaskRepository {}

typedef _Result = Either<Failure, OverrunAlertPlanEntity?>;

void main() {
  late StreamController<Either<Failure, ActiveTimerEntity?>> timerCtrl;
  late StreamController<Either<Failure, List<TaskEntity>>> tasksCtrl;
  late WatchOverrunAlertPlanUseCase useCase;

  final t0 = DateTime(2026, 10, 7, 10);
  TaskEntity task(String id, {int estimated = 30, String title = 'T'}) =>
      TaskEntity(
        id: id,
        title: title,
        listId: 'l1',
        createdAt: t0,
        estimatedMinutes: estimated,
      );
  ActiveTimerEntity active(
    String id, {
    TimerTargetTypeEnum type = TimerTargetTypeEnum.task,
    TimerStatusEnum status = TimerStatusEnum.running,
  }) => ActiveTimerEntity(
    targetId: id,
    targetType: type,
    listId: 'l1',
    startedAt: t0,
    status: status,
  );

  setUp(() {
    final timerRepo = _MockTimerRepo();
    final taskRepo = _MockTaskRepo();
    timerCtrl = StreamController<Either<Failure, ActiveTimerEntity?>>();
    tasksCtrl = StreamController<Either<Failure, List<TaskEntity>>>();
    when(() => timerRepo.watchActive()).thenAnswer((_) => timerCtrl.stream);
    when(
      () => taskRepo.watchTasks(includeDone: true),
    ).thenAnswer((_) => tasksCtrl.stream);
    useCase = WatchOverrunAlertPlanUseCase(
      timerRepo,
      taskRepo,
      const PlanOverrunAlertsUseCase(),
    );
  });

  tearDown(() async {
    await timerCtrl.close();
    await tasksCtrl.close();
  });

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  test('should not emit until timer and tasks arrive', () async {
    final out = <_Result>[];
    final sub = useCase(const NoParams()).listen(out.add);
    timerCtrl.add(Right(active('t1')));
    await pump();
    expect(out, isEmpty);
    tasksCtrl.add(Right([task('t1')]));
    await pump();
    expect(out, hasLength(1));
    await sub.cancel();
  });

  test('should emit plan for running task with estimate', () async {
    final out = <_Result>[];
    final sub = useCase(const NoParams()).listen(out.add);
    timerCtrl.add(Right(active('t1')));
    tasksCtrl.add(Right([task('t1', title: 'Tela')]));
    await pump();
    final plan = out.single.getRight().toNullable();
    expect(plan?.targetId, 't1');
    expect(plan?.title, 'Tela');
    await sub.cancel();
  });

  test('should emit null when timer is paused (cancels)', () async {
    final out = <_Result>[];
    final sub = useCase(const NoParams()).listen(out.add);
    tasksCtrl.add(Right([task('t1')]));
    timerCtrl
      ..add(Right(active('t1')))
      ..add(Right(active('t1', status: TimerStatusEnum.paused)));
    await pump();
    expect(out.last.isRight(), isTrue);
    expect(out.last.getRight().toNullable(), isNull);
    await sub.cancel();
  });

  test('should emit null when timer stops', () async {
    final out = <_Result>[];
    final sub = useCase(const NoParams()).listen(out.add);
    tasksCtrl.add(Right([task('t1')]));
    timerCtrl
      ..add(Right(active('t1')))
      ..add(const Right(null));
    await pump();
    expect(out, hasLength(2));
    expect(out.last.isRight(), isTrue);
    expect(out.last.getRight().toNullable(), isNull);
    await sub.cancel();
  });

  test('should emit null then new plan when switching target', () async {
    final out = <_Result>[];
    final sub = useCase(const NoParams()).listen(out.add);
    tasksCtrl.add(Right([task('t1'), task('t2')]));
    timerCtrl
      ..add(Right(active('t1')))
      ..add(Right(active('a1', type: TimerTargetTypeEnum.appointment)))
      ..add(Right(active('t2')));
    await pump();
    final ids = out.map((e) => e.getRight().toNullable()?.targetId).toList();
    expect(ids, ['t1', null, 't2']);
    await sub.cancel();
  });

  test('should not re-emit when an unrelated task changes', () async {
    final out = <_Result>[];
    final sub = useCase(const NoParams()).listen(out.add);
    timerCtrl.add(Right(active('t1')));
    tasksCtrl.add(Right([task('t1'), task('t2')]));
    await pump();
    tasksCtrl.add(Right([task('t1'), task('t2', estimated: 90)]));
    await pump();
    expect(out, hasLength(1));
    await sub.cancel();
  });

  test('should emit Left when timer stream fails', () async {
    final out = <_Result>[];
    final sub = useCase(const NoParams()).listen(out.add);
    tasksCtrl.add(Right([task('t1')]));
    timerCtrl.add(const Left(NetworkFailure()));
    await pump();
    expect(out.single.isLeft(), isTrue);
    await sub.cancel();
  });

  test('should emit Left when tasks stream fails', () async {
    final out = <_Result>[];
    final sub = useCase(const NoParams()).listen(out.add);
    timerCtrl.add(Right(active('t1')));
    tasksCtrl.add(const Left(NetworkFailure()));
    await pump();
    expect(out.single.isLeft(), isTrue);
    await sub.cancel();
  });

  test('should cancel both sources on cancel', () async {
    final sub = useCase(const NoParams()).listen((_) {});
    await pump();
    expect(timerCtrl.hasListener, isTrue);
    expect(tasksCtrl.hasListener, isTrue);
    await sub.cancel();
    expect(timerCtrl.hasListener, isFalse);
    expect(tasksCtrl.hasListener, isFalse);
  });
}
