import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_action_enum.dart';
import 'package:meu_tempo/features/lock_screen/domain/usecases/handle_lock_screen_action_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/finish_timer_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/pause_timer_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/resume_timer_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockPause extends Mock implements PauseTimerUseCase {}

class _MockResume extends Mock implements ResumeTimerUseCase {}

class _MockFinish extends Mock implements FinishTimerUseCase {}

void main() {
  late _MockPause pause;
  late _MockResume resume;
  late _MockFinish finish;
  late HandleLockScreenActionUseCase useCase;
  final now = DateTime(2026, 10, 7, 15);

  setUpAll(() {
    registerFallbackValue(PauseTimerParams(targetId: 'x', now: now));
    registerFallbackValue(ResumeTimerParams(targetId: 'x', now: now));
    registerFallbackValue(FinishTimerParams(targetId: 'x', now: now));
  });

  setUp(() {
    pause = _MockPause();
    resume = _MockResume();
    finish = _MockFinish();
    when(() => pause(any())).thenAnswer((_) async => const Right(unit));
    when(() => resume(any())).thenAnswer((_) async => const Right(unit));
    when(() => finish(any())).thenAnswer((_) async => const Right(unit));
    useCase = HandleLockScreenActionUseCase(pause, resume, finish);
  });

  HandleLockScreenActionParams params(LockScreenActionEnum action) =>
      HandleLockScreenActionParams(action: action, targetId: 't1', now: now);

  test('pausar chama PauseTimerUseCase com o alvo e o instante', () async {
    final result = await useCase(params(LockScreenActionEnum.pause));

    expect(result, const Right<Failure, Unit>(unit));
    verify(() => pause(PauseTimerParams(targetId: 't1', now: now))).called(1);
    verifyNever(() => resume(any()));
    verifyNever(() => finish(any()));
  });

  test('continuar chama ResumeTimerUseCase', () async {
    final result = await useCase(params(LockScreenActionEnum.resume));

    expect(result, const Right<Failure, Unit>(unit));
    verify(() => resume(ResumeTimerParams(targetId: 't1', now: now))).called(1);
    verifyNever(() => pause(any()));
    verifyNever(() => finish(any()));
  });

  test('parar confirmado chama FinishTimerUseCase', () async {
    final result = await useCase(params(LockScreenActionEnum.stopConfirmed));

    expect(result, const Right<Failure, Unit>(unit));
    verify(() => finish(FinishTimerParams(targetId: 't1', now: now))).called(1);
    verifyNever(() => pause(any()));
    verifyNever(() => resume(any()));
  });

  test('falha do UseCase de destino é devolvida', () async {
    when(
      () => finish(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await useCase(params(LockScreenActionEnum.stopConfirmed));

    expect(result, const Left<Failure, Unit>(NetworkFailure()));
  });

  test('Params com mesmos valores são iguais', () {
    expect(
      params(LockScreenActionEnum.pause),
      params(LockScreenActionEnum.pause),
    );
  });
}
