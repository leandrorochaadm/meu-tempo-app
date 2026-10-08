import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_permission_status_enum.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_timer_entity.dart';
import 'package:meu_tempo/features/lock_screen/domain/lock_screen_failures.dart';
import 'package:meu_tempo/features/lock_screen/domain/usecases/get_lock_screen_permission_status_use_case.dart';
import 'package:meu_tempo/features/lock_screen/domain/usecases/watch_lock_screen_permission_warnings_use_case.dart';
import 'package:meu_tempo/features/lock_screen/domain/usecases/watch_lock_screen_timer_starts_use_case.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:mocktail/mocktail.dart';

import '../../fake_lock_screen_timer_gateway.dart';

class _MockWatchStarts extends Mock
    implements WatchLockScreenTimerStartsUseCase {}

final taskRunning = LockScreenTimerEntity(
  targetId: 't1',
  targetType: TimerTargetTypeEnum.task,
  title: 'Tela de login',
  listName: 'Trabalho',
  status: TimerStatusEnum.running,
  spentMinutes: 40,
  sessionStartedAt: DateTime(2026, 10, 7, 10),
);

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  late _MockWatchStarts watchStarts;
  late StreamController<LockScreenTimerEntity> starts;
  late FakeLockScreenTimerGateway gateway;
  late WatchLockScreenPermissionWarningsUseCase useCase;
  late List<Either<Failure, Unit>> emitted;
  late StreamSubscription<Either<Failure, Unit>> sub;

  setUpAll(() => registerFallbackValue(const NoParams()));

  setUp(() {
    watchStarts = _MockWatchStarts();
    starts = StreamController<LockScreenTimerEntity>();
    when(() => watchStarts(any())).thenAnswer((_) => starts.stream);
    gateway = FakeLockScreenTimerGateway();
    useCase = WatchLockScreenPermissionWarningsUseCase(
      watchStarts,
      GetLockScreenPermissionStatusUseCase(gateway),
    );
    emitted = [];
    sub = useCase(const NoParams()).listen(emitted.add);
  });

  tearDown(() async {
    await sub.cancel();
    await starts.close();
    await gateway.dispose();
  });

  Future<void> start() async {
    starts.add(taskRunning);
    await flush();
  }

  test('start with notifications off warns', () async {
    gateway.permissionResult =
        const Right(LockScreenPermissionStatusEnum.denied);

    await start();

    expect(emitted, [const Right(unit)]);
    expect(gateway.permissionChecks, 1);
  });

  test('start with notifications on does not warn', () async {
    gateway.permissionResult =
        const Right(LockScreenPermissionStatusEnum.granted);

    await start();

    expect(emitted, isEmpty);
  });

  test('in the browser (unsupported) never warns', () async {
    gateway.permissionResult =
        const Right(LockScreenPermissionStatusEnum.unsupported);

    await start();

    expect(emitted, isEmpty);
  });

  test('failure reading the permission becomes a Left', () async {
    gateway.permissionResult = const Left(LockScreenPlatformFailure());

    await start();

    expect(emitted, [const Left(LockScreenPlatformFailure())]);
  });

  test('reads the permission on every start', () async {
    gateway.permissionResult =
        const Right(LockScreenPermissionStatusEnum.denied);
    await start();
    gateway.permissionResult =
        const Right(LockScreenPermissionStatusEnum.granted);
    await start();

    expect(emitted, [const Right(unit)]);
    expect(gateway.permissionChecks, 2);
  });

  test('without a start it does not read the permission', () async {
    await flush();

    expect(gateway.permissionChecks, 0);
  });

  test('cancelling cancels the source', () async {
    await sub.cancel();

    expect(starts.hasListener, isFalse);
  });
}
