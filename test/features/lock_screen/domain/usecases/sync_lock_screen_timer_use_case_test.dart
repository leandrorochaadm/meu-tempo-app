import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_permission_status_enum.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_timer_entity.dart';
import 'package:meu_tempo/features/lock_screen/domain/lock_screen_failures.dart';
import 'package:meu_tempo/features/lock_screen/domain/usecases/sync_lock_screen_timer_use_case.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';

import '../../fake_lock_screen_timer_gateway.dart';

void main() {
  late FakeLockScreenTimerGateway gateway;
  late SyncLockScreenTimerUseCase useCase;

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

  setUp(() {
    gateway = FakeLockScreenTimerGateway();
    useCase = SyncLockScreenTimerUseCase(gateway);
  });

  test('with a timer: shows it on the lock screen', () async {
    final result = await useCase(SyncLockScreenTimerParams(timer: taskRunning));

    expect(result, const Right<Failure, Unit>(unit));
    expect(gateway.pushes, [taskRunning]);
  });

  test('paused is also shown (stays in view)', () async {
    await useCase(SyncLockScreenTimerParams(timer: taskPaused));

    expect(gateway.pushes, [taskPaused]);
  });

  test('without a timer: removes it from the lock screen', () async {
    await useCase(const SyncLockScreenTimerParams(timer: null));

    expect(gateway.pushes, [null]);
  });

  test('phone failure on show is returned', () async {
    gateway.showResult = const Left(LockScreenPlatformFailure());

    final result = await useCase(SyncLockScreenTimerParams(timer: taskRunning));

    expect(result, const Left<Failure, Unit>(LockScreenPlatformFailure()));
  });

  test('phone failure on clear is returned', () async {
    gateway.clearResult = const Left(LockScreenPlatformFailure());

    final result = await useCase(const SyncLockScreenTimerParams(timer: null));

    expect(result, const Left<Failure, Unit>(LockScreenPlatformFailure()));
  });

  test('primeiro start: pede a permissão e depois mostra', () async {
    gateway.permissionResult = const Right(
      LockScreenPermissionStatusEnum.notRequested,
    );

    await useCase(SyncLockScreenTimerParams(timer: taskRunning));

    expect(gateway.permissionRequests, 1);
    expect(gateway.pushes, [taskRunning]);
  });

  test('permissão já respondida: não pede de novo', () async {
    for (final status in [
      LockScreenPermissionStatusEnum.granted,
      LockScreenPermissionStatusEnum.denied,
    ]) {
      gateway.permissionResult = Right(status);
      await useCase(SyncLockScreenTimerParams(timer: taskRunning));
    }

    expect(gateway.permissionRequests, 0);
  });

  test('pausado não pede permissão', () async {
    gateway.permissionResult = const Right(
      LockScreenPermissionStatusEnum.notRequested,
    );

    await useCase(SyncLockScreenTimerParams(timer: taskPaused));

    expect(gateway.permissionRequests, 0);
    expect(gateway.pushes, [taskPaused]);
  });

  test('falha ao ler a permissão não impede mostrar', () async {
    gateway.permissionResult = const Left(LockScreenPlatformFailure());

    await useCase(SyncLockScreenTimerParams(timer: taskRunning));

    expect(gateway.pushes, [taskRunning]);
  });

  test('usuário nega: mostra mesmo assim', () async {
    gateway.permissionResult = const Right(
      LockScreenPermissionStatusEnum.notRequested,
    );
    gateway.requestPermissionResult = const Right(
      LockScreenPermissionStatusEnum.denied,
    );

    final result = await useCase(SyncLockScreenTimerParams(timer: taskRunning));

    expect(result, const Right<Failure, Unit>(unit));
    expect(gateway.pushes, [taskRunning]);
  });

  test('sem cronômetro: limpa sem ler a permissão', () async {
    await useCase(const SyncLockScreenTimerParams(timer: null));

    expect(gateway.permissionChecks, 0);
  });

  test('params with the same timer are equal', () {
    expect(
      SyncLockScreenTimerParams(timer: taskRunning),
      SyncLockScreenTimerParams(timer: taskRunning),
    );
  });
}
