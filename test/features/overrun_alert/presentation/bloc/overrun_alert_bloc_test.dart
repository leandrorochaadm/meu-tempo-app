import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/overrun_alert/domain/entities/overrun_alert_entity.dart';
import 'package:meu_tempo/features/overrun_alert/domain/entities/overrun_alert_plan_entity.dart';
import 'package:meu_tempo/features/overrun_alert/domain/usecases/sync_overrun_alert_schedule_use_case.dart';
import 'package:meu_tempo/features/overrun_alert/domain/usecases/watch_overrun_alert_plan_use_case.dart';
import 'package:meu_tempo/features/overrun_alert/domain/usecases/watch_overrun_alerts_use_case.dart';
import 'package:meu_tempo/features/overrun_alert/presentation/bloc/overrun_alert_bloc.dart';
import 'package:meu_tempo/features/task/domain/usecases/pause_timer_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../../fake_overrun_alert_scheduler.dart';

class _MockWatchPlan extends Mock implements WatchOverrunAlertPlanUseCase {}

class _MockPause extends Mock implements PauseTimerUseCase {}

typedef _PlanResult = Either<Failure, OverrunAlertPlanEntity?>;

void main() {
  late FakeOverrunAlertScheduler scheduler;
  late _MockWatchPlan watchPlan;
  late _MockPause pause;
  late List<StreamController<_PlanResult>> planCtrls;

  final at = DateTime(2026, 10, 7, 10, 30);
  OverrunAlertPlanEntity planFor(String id) => OverrunAlertPlanEntity(
    targetId: id,
    title: 'Tela de login',
    firstAlertAt: at,
    repeatInterval: const Duration(hours: 1),
  );
  OverrunAlertEntity alertFor(String id) =>
      OverrunAlertEntity(targetId: id, title: 'Tela de login', alertAt: at);
  final plan = planFor('t1');
  final alert = alertFor('t1');

  StreamController<_PlanResult> ctrl() => planCtrls.last;

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  setUpAll(() {
    registerFallbackValue(PauseTimerParams(targetId: 't1', now: at));
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    scheduler = FakeOverrunAlertScheduler();
    watchPlan = _MockWatchPlan();
    pause = _MockPause();
    planCtrls = [];
    when(() => watchPlan(any())).thenAnswer((_) {
      final c = StreamController<_PlanResult>();
      planCtrls.add(c);
      return c.stream;
    });
    when(() => pause(any())).thenAnswer((_) async => const Right(unit));
  });

  tearDown(() async {
    for (final c in planCtrls) {
      await c.close();
    }
    await scheduler.dispose();
  });

  OverrunAlertBloc build() => OverrunAlertBloc(
    watchPlan,
    SyncOverrunAlertScheduleUseCase(scheduler),
    WatchOverrunAlertsUseCase(scheduler),
    pause,
  );

  blocTest<OverrunAlertBloc, OverrunAlertState>(
    'should schedule when plan arrives',
    build: build,
    act: (bloc) async {
      bloc.add(const OverrunAlertStarted());
      await pump();
      ctrl().add(Right(plan));
      await pump();
    },
    expect: () => <OverrunAlertState>[],
    verify: (_) => expect(scheduler.calls, [plan]),
  );

  blocTest<OverrunAlertBloc, OverrunAlertState>(
    'should show alert when scheduler fires',
    build: build,
    act: (bloc) async {
      bloc.add(const OverrunAlertStarted());
      await pump();
      ctrl().add(Right(plan));
      await pump();
      scheduler.fire(alert);
      await pump();
    },
    expect: () => [OverrunAlertVisible(alert)],
  );

  blocTest<OverrunAlertBloc, OverrunAlertState>(
    'should cancel and hide when timer is paused or stopped',
    build: build,
    act: (bloc) async {
      bloc.add(const OverrunAlertStarted());
      await pump();
      ctrl().add(Right(plan));
      await pump();
      scheduler.fire(alert);
      await pump();
      ctrl().add(const Right(null));
      await pump();
    },
    expect: () => [OverrunAlertVisible(alert), const OverrunAlertHidden()],
    verify: (_) => expect(scheduler.calls, [plan, null]),
  );

  blocTest<OverrunAlertBloc, OverrunAlertState>(
    'should cancel and hide when switching target',
    build: build,
    act: (bloc) async {
      bloc.add(const OverrunAlertStarted());
      await pump();
      ctrl().add(Right(plan));
      await pump();
      scheduler.fire(alert);
      await pump();
      ctrl().add(Right(planFor('t2')));
      await pump();
    },
    expect: () => [OverrunAlertVisible(alert), const OverrunAlertHidden()],
  );

  blocTest<OverrunAlertBloc, OverrunAlertState>(
    'should keep alert when plan changes for the same target',
    build: build,
    act: (bloc) async {
      bloc.add(const OverrunAlertStarted());
      await pump();
      ctrl().add(Right(plan));
      await pump();
      scheduler.fire(alert);
      await pump();
      ctrl().add(
        Right(
          OverrunAlertPlanEntity(
            targetId: 't1',
            title: 'Tela de login',
            firstAlertAt: at.add(const Duration(minutes: 5)),
            repeatInterval: const Duration(hours: 1),
          ),
        ),
      );
      await pump();
    },
    expect: () => [OverrunAlertVisible(alert)],
  );

  blocTest<OverrunAlertBloc, OverrunAlertState>(
    'should hide on dismiss and show again on next fire',
    build: build,
    act: (bloc) async {
      bloc.add(const OverrunAlertStarted());
      await pump();
      ctrl().add(Right(plan));
      await pump();
      scheduler.fire(alert);
      await pump();
      bloc.add(const OverrunAlertDismissed());
      await pump();
      scheduler.fire(alert);
      await pump();
    },
    expect: () => [
      OverrunAlertVisible(alert),
      const OverrunAlertHidden(),
      OverrunAlertVisible(alert),
    ],
  );

  blocTest<OverrunAlertBloc, OverrunAlertState>(
    'should pause the alert target on Pausar',
    build: build,
    act: (bloc) async {
      bloc.add(const OverrunAlertStarted());
      await pump();
      ctrl().add(Right(plan));
      await pump();
      scheduler.fire(alert);
      await pump();
      bloc.add(const OverrunAlertPauseRequested());
      await pump();
    },
    expect: () => [OverrunAlertVisible(alert), const OverrunAlertHidden()],
    verify: (_) {
      final params =
          verify(() => pause(captureAny())).captured.single as PauseTimerParams;
      expect(params.targetId, 't1');
    },
  );

  blocTest<OverrunAlertBloc, OverrunAlertState>(
    'should emit PauseFailed with message when pause fails',
    build: build,
    setUp: () => when(
      () => pause(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure())),
    act: (bloc) async {
      bloc.add(const OverrunAlertStarted());
      await pump();
      ctrl().add(Right(plan));
      await pump();
      scheduler.fire(alert);
      await pump();
      bloc.add(const OverrunAlertPauseRequested());
      await pump();
    },
    expect: () => [
      OverrunAlertVisible(alert),
      OverrunAlertPauseFailed(alert, 'Sem conexão. Verifique a internet.'),
    ],
  );

  blocTest<OverrunAlertBloc, OverrunAlertState>(
    'should emit PauseFailed again when retry also fails',
    build: build,
    setUp: () => when(
      () => pause(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure())),
    act: (bloc) async {
      bloc.add(const OverrunAlertStarted());
      await pump();
      ctrl().add(Right(plan));
      await pump();
      scheduler.fire(alert);
      await pump();
      bloc.add(const OverrunAlertPauseRequested());
      await pump();
      bloc.add(const OverrunAlertPauseRequested());
      await pump();
    },
    expect: () => [
      OverrunAlertVisible(alert),
      OverrunAlertPauseFailed(alert, 'Sem conexão. Verifique a internet.'),
      OverrunAlertVisible(alert),
      OverrunAlertPauseFailed(alert, 'Sem conexão. Verifique a internet.'),
    ],
  );

  blocTest<OverrunAlertBloc, OverrunAlertState>(
    'should ignore fire for an obsolete plan',
    build: build,
    act: (bloc) async {
      bloc.add(const OverrunAlertStarted());
      await pump();
      ctrl().add(Right(planFor('t2')));
      await pump();
      scheduler.fire(alert);
      await pump();
    },
    expect: () => <OverrunAlertState>[],
  );

  blocTest<OverrunAlertBloc, OverrunAlertState>(
    'should keep schedule on read failure',
    build: build,
    act: (bloc) async {
      bloc.add(const OverrunAlertStarted());
      await pump();
      ctrl().add(Right(plan));
      await pump();
      ctrl().add(const Left(NetworkFailure()));
      await pump();
    },
    expect: () => <OverrunAlertState>[],
    verify: (_) => expect(scheduler.calls, [plan]),
  );

  blocTest<OverrunAlertBloc, OverrunAlertState>(
    'should cancel and hide on sign out',
    build: build,
    act: (bloc) async {
      bloc.add(const OverrunAlertStarted());
      await pump();
      ctrl().add(Right(plan));
      await pump();
      scheduler.fire(alert);
      await pump();
      bloc.add(const OverrunAlertSignedOut());
      await pump();
    },
    expect: () => [OverrunAlertVisible(alert), const OverrunAlertHidden()],
    verify: (_) => expect(scheduler.calls, [plan, null]),
  );

  blocTest<OverrunAlertBloc, OverrunAlertState>(
    'should ignore stale plan after sign out',
    build: build,
    act: (bloc) async {
      bloc.add(const OverrunAlertStarted());
      await pump();
      final old = ctrl();
      bloc.add(const OverrunAlertSignedOut());
      await pump();
      old.add(Right(plan));
      await pump();
    },
    expect: () => [const OverrunAlertHidden()],
    verify: (_) => expect(scheduler.calls, [null]),
  );

  blocTest<OverrunAlertBloc, OverrunAlertState>(
    'should resubscribe from scratch on Started twice',
    build: build,
    act: (bloc) async {
      bloc.add(const OverrunAlertStarted());
      await pump();
      final first = ctrl();
      bloc.add(const OverrunAlertStarted());
      await pump();
      expect(planCtrls, hasLength(2));
      expect(first.hasListener, isFalse);
      ctrl().add(Right(plan));
      await pump();
    },
    verify: (_) => expect(scheduler.calls, [plan]),
  );

  test('should cancel subscriptions on close', () async {
    final bloc = build()..add(const OverrunAlertStarted());
    await pump();
    expect(ctrl().hasListener, isTrue);
    await bloc.close();
    expect(ctrl().hasListener, isFalse);
  });
}
