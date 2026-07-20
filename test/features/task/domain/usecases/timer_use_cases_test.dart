import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/domain/entities/active_timer_entity.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart';
import 'package:meu_tempo/features/task/domain/repositories/timer_repository.dart';
import 'package:meu_tempo/features/task/domain/task_failures.dart';
import 'package:meu_tempo/features/task/domain/usecases/register_manual_time_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/start_timer_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/stop_timer_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockTimerRepo extends Mock implements TimerRepository {}

class _MockTaskRepo extends Mock implements TaskRepository {}

class _FakeActiveTimer extends Fake implements ActiveTimerEntity {}

void main() {
  late _MockTimerRepo timerRepo;
  late _MockTaskRepo taskRepo;
  final now = DateTime(2026, 7, 20, 10, 30);

  setUpAll(() => registerFallbackValue(_FakeActiveTimer()));

  setUp(() {
    timerRepo = _MockTimerRepo();
    taskRepo = _MockTaskRepo();
  });

  group('StartTimerUseCase', () {
    test('recusa alvo que não é folha', () async {
      final result = await StartTimerUseCase(timerRepo, taskRepo)(
        StartTimerParams(targetId: 't1', targetIsLeaf: false, now: now),
      );
      expect(result, isA<Left<Failure, Unit>>());
      verifyNever(() => timerRepo.getActive());
    });

    test('pausa o cronômetro anterior somando o tempo e inicia o novo',
        () async {
      final previous = ActiveTimerEntity(
        targetId: 'old',
        startedAt: now.subtract(const Duration(minutes: 25)),
      );
      when(() => timerRepo.getActive())
          .thenAnswer((_) async => Right(previous));
      when(() => taskRepo.addSpentMinutes(any(), any()))
          .thenAnswer((_) async => const Right(unit));
      when(() => timerRepo.setActive(any()))
          .thenAnswer((_) async => const Right(unit));

      await StartTimerUseCase(timerRepo, taskRepo)(
        StartTimerParams(targetId: 'new', targetIsLeaf: true, now: now),
      );

      verify(() => taskRepo.addSpentMinutes('old', 25)).called(1);
      verify(() => timerRepo.setActive(any())).called(1);
    });
  });

  group('StopTimerUseCase', () {
    test('sem cronômetro ativo apenas retorna sucesso', () async {
      when(() => timerRepo.getActive())
          .thenAnswer((_) async => const Right(null));

      final result = await StopTimerUseCase(timerRepo, taskRepo)(
        StopTimerParams(now: now),
      );

      expect(result.isRight(), isTrue);
      verifyNever(() => taskRepo.addSpentMinutes(any(), any()));
    });

    test('soma o tempo decorrido e limpa', () async {
      final active = ActiveTimerEntity(
        targetId: 't1',
        startedAt: now.subtract(const Duration(minutes: 40)),
      );
      when(() => timerRepo.getActive()).thenAnswer((_) async => Right(active));
      when(() => taskRepo.addSpentMinutes(any(), any()))
          .thenAnswer((_) async => const Right(unit));
      when(() => timerRepo.clear()).thenAnswer((_) async => const Right(unit));

      await StopTimerUseCase(timerRepo, taskRepo)(StopTimerParams(now: now));

      verify(() => taskRepo.addSpentMinutes('t1', 40)).called(1);
      verify(() => timerRepo.clear()).called(1);
    });
  });

  group('RegisterManualTimeUseCase', () {
    test('recusa não-folha', () async {
      final result = await RegisterManualTimeUseCase(taskRepo)(
        const RegisterManualTimeParams(
          targetId: 't1',
          targetIsLeaf: false,
          minutes: 30,
        ),
      );
      expect(result, isA<Left<Failure, Unit>>());
    });

    test('recusa duração <= 0 com InvalidDurationFailure', () async {
      final result = await RegisterManualTimeUseCase(taskRepo)(
        const RegisterManualTimeParams(
          targetId: 't1',
          targetIsLeaf: true,
          minutes: 0,
        ),
      );
      result.getLeft().fold(() => fail('esperava Left'),
          (f) => expect(f, isA<InvalidDurationFailure>()));
    });

    test('soma os minutos na folha', () async {
      when(() => taskRepo.addSpentMinutes(any(), any()))
          .thenAnswer((_) async => const Right(unit));

      await RegisterManualTimeUseCase(taskRepo)(
        const RegisterManualTimeParams(
          targetId: 't1',
          targetIsLeaf: true,
          minutes: 30,
        ),
      );

      verify(() => taskRepo.addSpentMinutes('t1', 30)).called(1);
    });
  });
}
