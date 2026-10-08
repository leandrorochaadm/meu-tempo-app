import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_timer_entity.dart';
import 'package:meu_tempo/features/lock_screen/domain/usecases/watch_lock_screen_timer_starts_use_case.dart';
import 'package:meu_tempo/features/lock_screen/domain/usecases/watch_lock_screen_timer_use_case.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchLockScreenTimer extends Mock
    implements WatchLockScreenTimerUseCase {}

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
final taskResumed = LockScreenTimerEntity(
  targetId: 't1',
  targetType: TimerTargetTypeEnum.task,
  title: 'Tela de login',
  listName: 'Trabalho',
  status: TimerStatusEnum.running,
  spentMinutes: 65,
  sessionStartedAt: DateTime(2026, 10, 7, 11),
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

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  late _MockWatchLockScreenTimer watch;
  late StreamController<Either<Failure, LockScreenTimerEntity?>> source;
  late WatchLockScreenTimerStartsUseCase useCase;
  late List<LockScreenTimerEntity> emitted;
  late StreamSubscription<LockScreenTimerEntity> sub;

  setUpAll(() => registerFallbackValue(const NoParams()));

  setUp(() {
    watch = _MockWatchLockScreenTimer();
    source = StreamController<Either<Failure, LockScreenTimerEntity?>>();
    when(() => watch(any())).thenAnswer((_) => source.stream);
    useCase = WatchLockScreenTimerStartsUseCase(watch);
    emitted = [];
    sub = useCase(const NoParams()).listen(emitted.add);
  });

  tearDown(() async {
    await sub.cancel();
    await source.close();
  });

  Future<void> push(Either<Failure, LockScreenTimerEntity?> value) async {
    source.add(value);
    await flush();
  }

  test('opening the app with the timer running is not a start', () async {
    await push(Right(taskRunning));

    expect(emitted, isEmpty);
  });

  test('start from nothing', () async {
    await push(const Right(null));
    await push(Right(taskRunning));

    expect(emitted, [taskRunning]);
  });

  test('start on another target (goes through nothing in view)', () async {
    await push(Right(taskRunning));
    await push(const Right(null));
    await push(Right(appointmentRunning));

    expect(emitted, [appointmentRunning]);
  });

  test('resuming the paused one is a start', () async {
    await push(Right(taskPaused));
    await push(Right(taskResumed));

    expect(emitted, [taskResumed]);
  });

  test('pausing is not a start', () async {
    await push(Right(taskRunning));
    await push(Right(taskPaused));

    expect(emitted, isEmpty);
  });

  test('read failure is ignored and does not become the baseline', () async {
    await push(const Left(NetworkFailure()));
    await push(const Right(null));
    await push(Right(taskRunning));

    expect(emitted, [taskRunning]);
  });

  test('failure in the middle does not break the comparison', () async {
    await push(Right(taskRunning));
    await push(const Left(NetworkFailure()));
    await push(Right(taskRunning));

    expect(emitted, isEmpty);
  });

  test('cancelling cancels the source', () async {
    await sub.cancel();

    expect(source.hasListener, isFalse);
  });
}
