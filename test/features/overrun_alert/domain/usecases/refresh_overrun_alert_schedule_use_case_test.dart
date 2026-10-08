import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/overrun_alert/domain/entities/overrun_alert_plan_entity.dart';
import 'package:meu_tempo/features/overrun_alert/domain/overrun_alert_failures.dart';
import 'package:meu_tempo/features/overrun_alert/domain/overrun_alert_rules.dart';
import 'package:meu_tempo/features/overrun_alert/domain/usecases/refresh_overrun_alert_schedule_use_case.dart';
import 'package:meu_tempo/features/overrun_alert/domain/usecases/sync_overrun_alert_schedule_use_case.dart';
import 'package:meu_tempo/features/overrun_alert/domain/usecases/watch_overrun_alert_plan_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../../fake_overrun_alert_scheduler.dart';

class _MockWatchPlan extends Mock implements WatchOverrunAlertPlanUseCase {}

void main() {
  late _MockWatchPlan watchPlan;
  late FakeOverrunAlertScheduler scheduler;
  late RefreshOverrunAlertScheduleUseCase useCase;

  final plan = OverrunAlertPlanEntity(
    targetId: 't1',
    title: 'Tela de login',
    firstAlertAt: DateTime(2026, 10, 7, 10, 30),
    repeatInterval: OverrunAlertRules.overrunRepeatInterval,
  );

  setUpAll(() => registerFallbackValue(const NoParams()));

  setUp(() {
    watchPlan = _MockWatchPlan();
    scheduler = FakeOverrunAlertScheduler();
    useCase = RefreshOverrunAlertScheduleUseCase(
      watchPlan,
      SyncOverrunAlertScheduleUseCase(scheduler),
    );
  });

  tearDown(() => scheduler.dispose());

  test('should schedule when timer has a plan', () async {
    when(() => watchPlan(any())).thenAnswer((_) => Stream.value(Right(plan)));

    final result = await useCase(const NoParams());

    expect(result, const Right<Failure, Unit>(unit));
    expect(scheduler.calls, [plan]);
  });

  test('should cancel when there is no plan', () async {
    when(
      () => watchPlan(any()),
    ).thenAnswer((_) => Stream.value(const Right(null)));

    final result = await useCase(const NoParams());

    expect(result, const Right<Failure, Unit>(unit));
    expect(scheduler.calls, [null]);
  });

  test('should keep schedule when plan read fails', () async {
    when(
      () => watchPlan(any()),
    ).thenAnswer((_) => Stream.value(const Left(NetworkFailure())));

    final result = await useCase(const NoParams());

    expect(result, const Left<Failure, Unit>(NetworkFailure()));
    expect(scheduler.calls, isEmpty);
  });

  test('should return Left when plan stream errors', () async {
    when(
      () => watchPlan(any()),
    ).thenAnswer((_) => Stream.error(Exception('boom')));

    final result = await useCase(const NoParams());

    expect(result, const Left<Failure, Unit>(ServerFailure()));
    expect(scheduler.calls, isEmpty);
  });

  test('should return Left when plan stream closes empty', () async {
    when(() => watchPlan(any())).thenAnswer((_) => const Stream.empty());

    final result = await useCase(const NoParams());

    expect(result, const Left<Failure, Unit>(ServerFailure()));
    expect(scheduler.calls, isEmpty);
  });

  test('should return Left when scheduler fails', () async {
    scheduler.scheduleResult = const Left(OverrunAlertPlatformFailure());
    when(() => watchPlan(any())).thenAnswer((_) => Stream.value(Right(plan)));

    final result = await useCase(const NoParams());

    expect(result, const Left<Failure, Unit>(OverrunAlertPlatformFailure()));
  });

  test('should read the plan only once', () async {
    final controller =
        StreamController<Either<Failure, OverrunAlertPlanEntity?>>();
    addTearDown(controller.close);
    when(() => watchPlan(any())).thenAnswer((_) => controller.stream);

    final future = useCase(const NoParams());
    controller.add(Right(plan));
    await future;

    expect(controller.hasListener, isFalse);
  });
}
