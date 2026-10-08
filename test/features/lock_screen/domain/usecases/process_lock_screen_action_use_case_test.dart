import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/auth_failures.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/auth/domain/entities/user_entity.dart';
import 'package:meu_tempo/features/auth/domain/repositories/auth_repository.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_action_enum.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_timer_entity.dart';
import 'package:meu_tempo/features/lock_screen/domain/usecases/handle_lock_screen_action_use_case.dart';
import 'package:meu_tempo/features/lock_screen/domain/usecases/process_lock_screen_action_use_case.dart';
import 'package:meu_tempo/features/lock_screen/domain/usecases/watch_lock_screen_timer_use_case.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockHandle extends Mock implements HandleLockScreenActionUseCase {}

class _MockWatch extends Mock implements WatchLockScreenTimerUseCase {}

void main() {
  late _MockAuthRepository auth;
  late _MockHandle handle;
  late _MockWatch watch;
  late ProcessLockScreenActionUseCase useCase;

  final now = DateTime(2026, 10, 7, 10, 5);
  const user = UserEntity(uid: 'u1', email: 'leandro@example.com');
  final params = HandleLockScreenActionParams(
    action: LockScreenActionEnum.pause,
    targetId: 't1',
    now: now,
  );
  final paused = LockScreenTimerEntity(
    targetId: 't1',
    targetType: TimerTargetTypeEnum.task,
    title: 'Tela de login',
    listName: 'Trabalho',
    status: TimerStatusEnum.paused,
    spentMinutes: 45,
    sessionStartedAt: now,
  );

  setUpAll(() {
    registerFallbackValue(params);
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    auth = _MockAuthRepository();
    handle = _MockHandle();
    watch = _MockWatch();
    when(() => auth.authState()).thenAnswer((_) => Stream.value(user));
    when(() => handle(any())).thenAnswer((_) async => const Right(unit));
    when(() => watch(any())).thenAnswer((_) => Stream.value(Right(paused)));
    useCase = ProcessLockScreenActionUseCase(auth, handle, watch);
  });

  test('sem sessão devolve UnauthenticatedFailure e não age', () async {
    when(() => auth.authState()).thenAnswer((_) => Stream.value(null));

    final result = await useCase(params);

    expect(
      result,
      const Left<Failure, LockScreenTimerEntity?>(UnauthenticatedFailure()),
    );
    verifyNever(() => handle(any()));
    verifyNever(() => watch(any()));
  });

  test('espera a sessão restaurada antes de agir', () async {
    final controller = StreamController<UserEntity?>();
    addTearDown(controller.close);
    when(() => auth.authState()).thenAnswer((_) => controller.stream);

    final future = useCase(params);
    await Future<void>.delayed(Duration.zero);
    verifyNever(() => handle(any()));

    controller.add(user);
    final result = await future;

    expect(result, Right<Failure, LockScreenTimerEntity?>(paused));
    verify(() => handle(params)).called(1);
  });

  test('com sessão executa a ação e devolve o estado novo', () async {
    final result = await useCase(params);

    expect(result, Right<Failure, LockScreenTimerEntity?>(paused));
    verify(() => handle(params)).called(1);
  });

  test('parar confirmado: cronômetro some e devolve null', () async {
    when(() => watch(any())).thenAnswer((_) => Stream.value(const Right(null)));

    final result = await useCase(params);

    expect(result, const Right<Failure, LockScreenTimerEntity?>(null));
  });

  test('falha da ação é devolvida e não lê o estado', () async {
    when(
      () => handle(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await useCase(params);

    expect(
      result,
      const Left<Failure, LockScreenTimerEntity?>(NetworkFailure()),
    );
    verifyNever(() => watch(const NoParams()));
  });

  test('falha ao ler o estado é devolvida', () async {
    when(
      () => watch(any()),
    ).thenAnswer((_) => Stream.value(const Left(ServerFailure())));

    final result = await useCase(params);

    expect(
      result,
      const Left<Failure, LockScreenTimerEntity?>(ServerFailure()),
    );
  });
}
