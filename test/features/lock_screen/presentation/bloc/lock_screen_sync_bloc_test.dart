import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_timer_entity.dart';
import 'package:meu_tempo/features/lock_screen/domain/lock_screen_failures.dart';
import 'package:meu_tempo/features/lock_screen/domain/usecases/sync_lock_screen_timer_use_case.dart';
import 'package:meu_tempo/features/lock_screen/domain/usecases/watch_lock_screen_timer_use_case.dart';
import 'package:meu_tempo/features/lock_screen/presentation/bloc/lock_screen_sync_bloc.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:mocktail/mocktail.dart';

import '../../fake_lock_screen_timer_gateway.dart';

class _MockWatchLockScreenTimer extends Mock
    implements WatchLockScreenTimerUseCase {}

typedef _Result = Either<Failure, LockScreenTimerEntity?>;

void main() {
  late _MockWatchLockScreenTimer watch;
  late FakeLockScreenTimerGateway gateway;
  late List<StreamController<_Result>> sources;

  final taskRunning = LockScreenTimerEntity(
    targetId: 't1',
    targetType: TimerTargetTypeEnum.task,
    title: 'Tela de login',
    listName: 'Trabalho',
    status: TimerStatusEnum.running,
    spentMinutes: 40,
    sessionStartedAt: DateTime(2026, 10, 7, 10),
  );
  final taskPaused = LockScreenTimerEntity(
    targetId: 't1',
    targetType: TimerTargetTypeEnum.task,
    title: 'Tela de login',
    listName: 'Trabalho',
    status: TimerStatusEnum.paused,
    spentMinutes: 65,
    sessionStartedAt: DateTime(2026, 10, 7, 10, 25),
  );
  final appointmentRunning = LockScreenTimerEntity(
    targetId: 'a1',
    targetType: TimerTargetTypeEnum.appointment,
    title: 'Dentista',
    listName: 'Pessoal',
    status: TimerStatusEnum.running,
    spentMinutes: 0,
    sessionStartedAt: DateTime(2026, 10, 7, 11),
  );

  setUpAll(() => registerFallbackValue(const NoParams()));

  setUp(() {
    watch = _MockWatchLockScreenTimer();
    gateway = FakeLockScreenTimerGateway();
    sources = [];
    // Each subscription gets a new stream, so resubscription can be checked.
    when(() => watch(any())).thenAnswer((_) {
      final source = StreamController<_Result>();
      sources.add(source);
      return source.stream;
    });
  });

  tearDown(() async {
    for (final source in sources) {
      await source.close();
    }
  });

  LockScreenSyncBloc build() =>
      LockScreenSyncBloc(watch, SyncLockScreenTimerUseCase(gateway));

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  const wait = Duration(milliseconds: 10);

  test('initial state is Stopped and nothing is called', () {
    final bloc = build();

    expect(bloc.state, const LockScreenSyncStopped());
    expect(gateway.pushes, isEmpty);
    verifyNever(() => watch(any()));
    bloc.close();
  });

  blocTest<LockScreenSyncBloc, LockScreenSyncState>(
    'start: a running timer shows on the lock screen',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenSyncStarted());
      await flush();
      sources.single.add(Right(taskRunning));
      await flush();
    },
    wait: wait,
    expect: () => [LockScreenSyncVisible(taskRunning)],
    verify: (_) => expect(gateway.pushes, [taskRunning]),
  );

  blocTest<LockScreenSyncBloc, LockScreenSyncState>(
    'opening the app with no timer clears the lock screen',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenSyncStarted());
      await flush();
      sources.single.add(const Right(null));
      await flush();
    },
    wait: wait,
    expect: () => [const LockScreenSyncHidden()],
    verify: (_) => expect(gateway.pushes, [null]),
  );

  blocTest<LockScreenSyncBloc, LockScreenSyncState>(
    'pausing updates the lock screen to paused',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenSyncStarted());
      await flush();
      sources.single.add(Right(taskRunning));
      await flush();
      sources.single.add(Right(taskPaused));
      await flush();
    },
    wait: wait,
    expect: () => [
      LockScreenSyncVisible(taskRunning),
      LockScreenSyncVisible(taskPaused),
    ],
    verify: (_) => expect(gateway.pushes, [taskRunning, taskPaused]),
  );

  blocTest<LockScreenSyncBloc, LockScreenSyncState>(
    'start on another target swaps what shows, in order',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenSyncStarted());
      await flush();
      sources.single.add(Right(taskRunning));
      sources.single.add(const Right(null));
      sources.single.add(Right(appointmentRunning));
      await flush();
    },
    wait: wait,
    expect: () => [
      LockScreenSyncVisible(taskRunning),
      const LockScreenSyncHidden(),
      LockScreenSyncVisible(appointmentRunning),
    ],
    verify: (_) =>
        expect(gateway.pushes, [taskRunning, null, appointmentRunning]),
  );

  blocTest<LockScreenSyncBloc, LockScreenSyncState>(
    'stopping removes it from the lock screen',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenSyncStarted());
      await flush();
      sources.single.add(Right(taskRunning));
      await flush();
      sources.single.add(const Right(null));
      await flush();
    },
    wait: wait,
    expect: () => [
      LockScreenSyncVisible(taskRunning),
      const LockScreenSyncHidden(),
    ],
    verify: (_) => expect(gateway.pushes, [taskRunning, null]),
  );

  blocTest<LockScreenSyncBloc, LockScreenSyncState>(
    'signing out cancels the stream and clears the lock screen',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenSyncStarted());
      await flush();
      sources.single.add(Right(taskRunning));
      await flush();
      bloc.add(const LockScreenSyncSignedOut());
      await flush();
    },
    wait: wait,
    expect: () => [
      LockScreenSyncVisible(taskRunning),
      const LockScreenSyncStopped(),
    ],
    verify: (_) {
      expect(gateway.pushes, [taskRunning, null]);
      expect(sources.single.hasListener, isFalse);
    },
  );

  blocTest<LockScreenSyncBloc, LockScreenSyncState>(
    'late emission after sign-out does not show again',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenSyncStarted());
      await flush();
      bloc.add(const LockScreenSyncSignedOut());
      sources.single.add(Right(taskRunning));
      await flush();
    },
    wait: wait,
    expect: () => [const LockScreenSyncStopped()],
    verify: (_) => expect(gateway.pushes, [null]),
  );

  blocTest<LockScreenSyncBloc, LockScreenSyncState>(
    'opening signed out clears what was left on the lock screen',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenSyncSignedOut());
      await flush();
    },
    wait: wait,
    expect: () => [const LockScreenSyncStopped()],
    verify: (_) {
      expect(gateway.pushes, [null]);
      verifyNever(() => watch(any()));
    },
  );

  blocTest<LockScreenSyncBloc, LockScreenSyncState>(
    'returning to the foreground resubscribes and redraws without change',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenSyncStarted());
      await flush();
      sources[0].add(Right(taskRunning));
      await flush();
      bloc.add(const LockScreenSyncAppResumed());
      await flush();
      sources[1].add(Right(taskRunning));
      await flush();
    },
    wait: wait,
    expect: () => [LockScreenSyncVisible(taskRunning)],
    verify: (_) {
      expect(sources.length, 2);
      expect(sources[0].hasListener, isFalse);
      expect(gateway.pushes, [taskRunning, taskRunning]);
    },
  );

  blocTest<LockScreenSyncBloc, LockScreenSyncState>(
    'returning to the foreground fixes a timer changed on the other phone',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenSyncStarted());
      await flush();
      sources[0].add(Right(taskRunning));
      await flush();
      bloc.add(const LockScreenSyncAppResumed());
      await flush();
      sources[1].add(Right(appointmentRunning));
      await flush();
    },
    wait: wait,
    expect: () => [
      LockScreenSyncVisible(taskRunning),
      LockScreenSyncVisible(appointmentRunning),
    ],
    verify: (_) =>
        expect(gateway.pushes, [taskRunning, appointmentRunning]),
  );

  blocTest<LockScreenSyncBloc, LockScreenSyncState>(
    'returning to the foreground while signed out does nothing',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenSyncAppResumed());
      await flush();
    },
    wait: wait,
    expect: () => <LockScreenSyncState>[],
    verify: (_) {
      verifyNever(() => watch(any()));
      expect(gateway.pushes, isEmpty);
    },
  );

  blocTest<LockScreenSyncBloc, LockScreenSyncState>(
    'event of the old subscription is ignored after returning to foreground',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenSyncStarted());
      await flush();
      bloc.add(const LockScreenSyncAppResumed());
      sources[0].add(Right(taskRunning));
      await flush();
      sources[1].add(Right(appointmentRunning));
      await flush();
    },
    wait: wait,
    verify: (_) {
      expect(gateway.pushes.last, appointmentRunning);
      expect(gateway.pushes, isNot(contains(taskRunning)));
    },
  );

  blocTest<LockScreenSyncBloc, LockScreenSyncState>(
    'signing in again resubscribes from scratch',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenSyncStarted());
      await flush();
      bloc.add(const LockScreenSyncStarted());
      await flush();
    },
    wait: wait,
    verify: (_) {
      expect(sources.length, 2);
      expect(sources[0].hasListener, isFalse);
    },
  );

  blocTest<LockScreenSyncBloc, LockScreenSyncState>(
    'read failure keeps what is on screen',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenSyncStarted());
      await flush();
      sources.single.add(Right(taskRunning));
      await flush();
      sources.single.add(const Left(NetworkFailure()));
      await flush();
    },
    wait: wait,
    expect: () => [LockScreenSyncVisible(taskRunning)],
    verify: (_) => expect(gateway.pushes, [taskRunning]),
  );

  blocTest<LockScreenSyncBloc, LockScreenSyncState>(
    'after a read failure, returning to foreground syncs again',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenSyncStarted());
      await flush();
      sources[0].add(Right(taskRunning));
      sources[0].add(const Left(NetworkFailure()));
      await flush();
      bloc.add(const LockScreenSyncAppResumed());
      await flush();
      sources[1].add(const Right(null));
      await flush();
    },
    wait: wait,
    expect: () => [
      LockScreenSyncVisible(taskRunning),
      const LockScreenSyncHidden(),
    ],
    verify: (_) {
      expect(sources.length, 2);
      expect(gateway.pushes, [taskRunning, null]);
    },
  );

  blocTest<LockScreenSyncBloc, LockScreenSyncState>(
    'stream error does not bring the Bloc down',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenSyncStarted());
      await flush();
      sources.single.add(Right(taskRunning));
      await flush();
      sources.single.addError(Exception('x'));
      await flush();
      sources.single.add(const Right(null));
      await flush();
    },
    wait: wait,
    expect: () => [
      LockScreenSyncVisible(taskRunning),
      const LockScreenSyncHidden(),
    ],
    verify: (_) => expect(gateway.pushes, [taskRunning, null]),
  );

  blocTest<LockScreenSyncBloc, LockScreenSyncState>(
    'phone refuses to show: state does not change and the next event goes on',
    build: build,
    act: (bloc) async {
      gateway.showResult = const Left(LockScreenPlatformFailure());
      bloc.add(const LockScreenSyncStarted());
      await flush();
      sources.single.add(Right(taskRunning));
      await flush();
      gateway.showResult = const Right(unit);
      sources.single.add(Right(taskPaused));
      await flush();
    },
    wait: wait,
    expect: () => [LockScreenSyncVisible(taskPaused)],
    verify: (_) => expect(gateway.pushes, [taskRunning, taskPaused]),
  );

  blocTest<LockScreenSyncBloc, LockScreenSyncState>(
    'phone refuses to clear on sign-out: still stops mirroring',
    build: build,
    act: (bloc) async {
      gateway.clearResult = const Left(LockScreenPlatformFailure());
      bloc.add(const LockScreenSyncStarted());
      await flush();
      sources.single.add(Right(taskRunning));
      await flush();
      bloc.add(const LockScreenSyncSignedOut());
      await flush();
    },
    wait: wait,
    expect: () => [
      LockScreenSyncVisible(taskRunning),
      const LockScreenSyncStopped(),
    ],
  );

  test('closing the Bloc cancels the stream', () async {
    final bloc = build()..add(const LockScreenSyncStarted());
    await flush();

    await bloc.close();

    expect(sources.single.hasListener, isFalse);
  });
}
