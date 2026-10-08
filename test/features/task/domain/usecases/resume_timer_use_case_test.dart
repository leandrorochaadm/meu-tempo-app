import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/domain/entities/active_timer_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:meu_tempo/features/task/domain/repositories/timer_repository.dart';
import 'package:meu_tempo/features/task/domain/usecases/resume_timer_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockTimerRepo extends Mock implements TimerRepository {}

class _FakeActiveTimer extends Fake implements ActiveTimerEntity {}

void main() {
  late _MockTimerRepo timerRepo;
  late ResumeTimerUseCase useCase;
  final now = DateTime(2026, 7, 20, 10, 30);

  setUpAll(() => registerFallbackValue(_FakeActiveTimer()));

  setUp(() {
    timerRepo = _MockTimerRepo();
    when(() => timerRepo.replaceActiveIfUnchanged(
          expected: any(named: 'expected'),
          replacement: any(named: 'replacement'),
        )).thenAnswer((_) async => const Right(true));
    useCase = ResumeTimerUseCase(timerRepo);
  });

  ActiveTimerEntity active({
    String id = 't1',
    TimerStatusEnum status = TimerStatusEnum.paused,
  }) =>
      ActiveTimerEntity(
        targetId: id,
        targetType: TimerTargetTypeEnum.task,
        listId: 'l1',
        startedAt: now.subtract(const Duration(minutes: 25)),
        status: status,
      );

  void stubActive(ActiveTimerEntity? timer) =>
      when(() => timerRepo.getActive()).thenAnswer((_) async => Right(timer));

  ResumeTimerParams params() => ResumeTimerParams(targetId: 't1', now: now);

  void expectNoReplace() =>
      verifyNever(() => timerRepo.replaceActiveIfUnchanged(
            expected: any(named: 'expected'),
            replacement: any(named: 'replacement'),
          ));

  group('ResumeTimerUseCase', () {
    test('continua o pausado: mesmo alvo rodando a partir de agora', () async {
      final paused = active();
      stubActive(paused);

      final result = await useCase(params());

      expect(result, const Right<Failure, Unit>(unit));
      final captured = verify(() => timerRepo.replaceActiveIfUnchanged(
            expected: captureAny(named: 'expected'),
            replacement: captureAny(named: 'replacement'),
          )).captured;
      expect(captured[0], paused);
      final replacement = captured[1] as ActiveTimerEntity;
      expect(replacement.status, TimerStatusEnum.running);
      expect(replacement.startedAt, now);
      expect(replacement.targetId, paused.targetId);
      expect(replacement.targetType, paused.targetType);
      expect(replacement.listId, paused.listId);
    });

    test('já rodando: no-op', () async {
      stubActive(active(status: TimerStatusEnum.running));

      final result = await useCase(params());

      expect(result.isRight(), isTrue);
      expectNoReplace();
    });

    test('outro alvo ativo: no-op', () async {
      stubActive(active(id: 't2'));

      final result = await useCase(params());

      expect(result.isRight(), isTrue);
      expectNoReplace();
    });

    test('sem cronômetro: no-op', () async {
      stubActive(null);

      final result = await useCase(params());

      expect(result.isRight(), isTrue);
      expectNoReplace();
    });

    test('corrida perdida: Right(unit)', () async {
      stubActive(active());
      when(() => timerRepo.replaceActiveIfUnchanged(
            expected: any(named: 'expected'),
            replacement: any(named: 'replacement'),
          )).thenAnswer((_) async => const Right(false));

      final result = await useCase(params());

      expect(result, const Right<Failure, Unit>(unit));
    });

    test('falha ao ler devolve Left', () async {
      when(() => timerRepo.getActive())
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await useCase(params());

      expect(result, const Left<Failure, Unit>(ServerFailure()));
    });

    test('falha na troca devolve Left', () async {
      stubActive(active());
      when(() => timerRepo.replaceActiveIfUnchanged(
            expected: any(named: 'expected'),
            replacement: any(named: 'replacement'),
          )).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await useCase(params());

      expect(result, const Left<Failure, Unit>(NetworkFailure()));
    });
  });
}
