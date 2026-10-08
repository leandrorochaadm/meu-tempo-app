import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/appointment/domain/repositories/appointment_repository.dart';
import 'package:meu_tempo/features/task/domain/entities/active_timer_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart';
import 'package:meu_tempo/features/task/domain/repositories/time_entry_repository.dart';
import 'package:meu_tempo/features/task/domain/repositories/timer_repository.dart';
import 'package:meu_tempo/features/task/domain/task_failures.dart';
import 'package:meu_tempo/features/task/domain/usecases/record_timer_session_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/register_manual_time_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/start_timer_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/stop_timer_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockTimerRepo extends Mock implements TimerRepository {}

class _MockTaskRepo extends Mock implements TaskRepository {}

class _MockAppointmentRepo extends Mock implements AppointmentRepository {}

class _MockTimeEntryRepo extends Mock implements TimeEntryRepository {}

class _FakeActiveTimer extends Fake implements ActiveTimerEntity {}

class _FakeTimeEntry extends Fake implements TimeEntryEntity {}

void main() {
  late _MockTimerRepo timerRepo;
  late _MockTaskRepo taskRepo;
  late _MockAppointmentRepo apptRepo;
  late _MockTimeEntryRepo entryRepo;
  final now = DateTime(2026, 7, 20, 10, 30);

  setUpAll(() {
    registerFallbackValue(_FakeActiveTimer());
    registerFallbackValue(_FakeTimeEntry());
  });

  setUp(() {
    timerRepo = _MockTimerRepo();
    taskRepo = _MockTaskRepo();
    apptRepo = _MockAppointmentRepo();
    entryRepo = _MockTimeEntryRepo();
    when(() => taskRepo.addSpentMinutes(any(), any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => apptRepo.addSpentMinutes(any(), any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => entryRepo.add(any())).thenAnswer((_) async => const Right(unit));
    when(() => timerRepo.setActive(any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => timerRepo.clear()).thenAnswer((_) async => const Right(unit));
    when(() => timerRepo.claimActive())
        .thenAnswer((_) async => const Right(null));
  });

  RecordTimerSessionUseCase recordUseCase() =>
      RecordTimerSessionUseCase(taskRepo, apptRepo, entryRepo);
  StartTimerUseCase startUseCase() =>
      StartTimerUseCase(timerRepo, recordUseCase());
  StopTimerUseCase stopUseCase() => StopTimerUseCase(timerRepo, recordUseCase());
  RegisterManualTimeUseCase manualUseCase() =>
      RegisterManualTimeUseCase(taskRepo, entryRepo);

  group('StartTimerUseCase', () {
    test('recusa tarefa que não é folha', () async {
      final result = await startUseCase()(
        StartTimerParams(
          targetId: 't1',
          targetType: TimerTargetTypeEnum.task,
          targetIsLeaf: false,
          listId: 'l1',
          now: now,
        ),
      );
      expect(result, isA<Left<Failure, Unit>>());
      verifyNever(() => timerRepo.claimActive());
    });

    test('compromisso pode iniciar mesmo com targetIsLeaf false', () async {
      when(() => timerRepo.claimActive())
          .thenAnswer((_) async => const Right(null));

      final result = await startUseCase()(
        StartTimerParams(
          targetId: 'a1',
          targetType: TimerTargetTypeEnum.appointment,
          targetIsLeaf: false,
          listId: 'l1',
          now: now,
        ),
      );

      expect(result.isRight(), isTrue);
      verify(() => timerRepo.setActive(any())).called(1);
    });

    test('pausa o anterior (tarefa) somando tempo e gravando registro',
        () async {
      final previous = ActiveTimerEntity(
        targetId: 'old',
        targetType: TimerTargetTypeEnum.task,
        listId: 'lOld',
        startedAt: now.subtract(const Duration(minutes: 25)),
      );
      when(() => timerRepo.claimActive())
          .thenAnswer((_) async => Right(previous));

      await startUseCase()(
        StartTimerParams(
          targetId: 'new',
          targetType: TimerTargetTypeEnum.task,
          targetIsLeaf: true,
          listId: 'lNew',
          now: now,
        ),
      );

      verify(() => taskRepo.addSpentMinutes('old', 25)).called(1);
      verify(() => entryRepo.add(any())).called(1);
      verifyNever(() => apptRepo.addSpentMinutes(any(), any()));
      verify(() => timerRepo.setActive(any())).called(1);
    });

    test('pausa o anterior (compromisso) somando no repo de compromisso',
        () async {
      final previous = ActiveTimerEntity(
        targetId: 'appt',
        targetType: TimerTargetTypeEnum.appointment,
        listId: 'lA',
        startedAt: now.subtract(const Duration(minutes: 10)),
      );
      when(() => timerRepo.claimActive())
          .thenAnswer((_) async => Right(previous));

      await startUseCase()(
        StartTimerParams(
          targetId: 'new',
          targetType: TimerTargetTypeEnum.task,
          targetIsLeaf: true,
          listId: 'lNew',
          now: now,
        ),
      );

      verify(() => apptRepo.addSpentMinutes('appt', 10)).called(1);
      verifyNever(() => taskRepo.addSpentMinutes(any(), any()));
    });

    test('anterior pausado não soma tempo e o novo começa rodando', () async {
      final previous = ActiveTimerEntity(
        targetId: 'old',
        targetType: TimerTargetTypeEnum.task,
        listId: 'lOld',
        startedAt: now.subtract(const Duration(minutes: 25)),
        status: TimerStatusEnum.paused,
      );
      when(() => timerRepo.claimActive())
          .thenAnswer((_) async => Right(previous));

      await startUseCase()(
        StartTimerParams(
          targetId: 'new',
          targetType: TimerTargetTypeEnum.task,
          targetIsLeaf: true,
          listId: 'lNew',
          now: now,
        ),
      );

      verifyNever(() => taskRepo.addSpentMinutes(any(), any()));
      verifyNever(() => entryRepo.add(any()));
      final captured =
          verify(() => timerRepo.setActive(captureAny())).captured.single
              as ActiveTimerEntity;
      expect(captured.status, TimerStatusEnum.running);
    });

    test('start no mesmo alvo pausado volta a contar', () async {
      final previous = ActiveTimerEntity(
        targetId: 't1',
        targetType: TimerTargetTypeEnum.task,
        listId: 'l1',
        startedAt: now.subtract(const Duration(minutes: 25)),
        status: TimerStatusEnum.paused,
      );
      when(() => timerRepo.claimActive())
          .thenAnswer((_) async => Right(previous));

      await startUseCase()(
        StartTimerParams(
          targetId: 't1',
          targetType: TimerTargetTypeEnum.task,
          targetIsLeaf: true,
          listId: 'l1',
          now: now,
        ),
      );

      verifyNever(() => taskRepo.addSpentMinutes(any(), any()));
      final captured =
          verify(() => timerRepo.setActive(captureAny())).captured.single
              as ActiveTimerEntity;
      expect(captured.targetId, 't1');
      expect(captured.startedAt, now);
      expect(captured.status, TimerStatusEnum.running);
    });

    test('falha ao somar o anterior não impede o novo start', () async {
      final previous = ActiveTimerEntity(
        targetId: 'old',
        targetType: TimerTargetTypeEnum.task,
        listId: 'lOld',
        startedAt: now.subtract(const Duration(minutes: 25)),
      );
      when(() => timerRepo.claimActive())
          .thenAnswer((_) async => Right(previous));
      when(() => taskRepo.addSpentMinutes(any(), any()))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await startUseCase()(
        StartTimerParams(
          targetId: 'new',
          targetType: TimerTargetTypeEnum.task,
          targetIsLeaf: true,
          listId: 'lNew',
          now: now,
        ),
      );

      expect(result.isRight(), isTrue);
      verify(() => timerRepo.setActive(any())).called(1);
    });
  });

  group('StopTimerUseCase', () {
    test('sem cronômetro ativo apenas retorna sucesso', () async {
      when(() => timerRepo.claimActive())
          .thenAnswer((_) async => const Right(null));

      final result = await stopUseCase()(StopTimerParams(now: now));

      expect(result.isRight(), isTrue);
      verifyNever(() => taskRepo.addSpentMinutes(any(), any()));
      verifyNever(() => entryRepo.add(any()));
    });

    test('soma o tempo na folha e grava registro (claim já limpa)', () async {
      final active = ActiveTimerEntity(
        targetId: 't1',
        targetType: TimerTargetTypeEnum.task,
        listId: 'l1',
        startedAt: now.subtract(const Duration(minutes: 40)),
      );
      when(() => timerRepo.claimActive())
          .thenAnswer((_) async => Right(active));

      await stopUseCase()(StopTimerParams(now: now));

      verify(() => taskRepo.addSpentMinutes('t1', 40)).called(1);
      verify(() => entryRepo.add(any())).called(1);
      // Não chama clear separado — o claim atômico já limpou o cronômetro.
      verifyNever(() => timerRepo.clear());
    });

    test('idempotente: vários "Parar" registram o tempo uma única vez', () async {
      final active = ActiveTimerEntity(
        targetId: 't1',
        targetType: TimerTargetTypeEnum.task,
        listId: 'l1',
        startedAt: now.subtract(const Duration(minutes: 40)),
      );
      // Simula a corrida: só o primeiro claim vence (recebe o timer); os toques
      // seguintes encontram o cronômetro já limpo e recebem null.
      var claims = 0;
      when(() => timerRepo.claimActive()).thenAnswer((_) async {
        claims++;
        return claims == 1 ? Right(active) : const Right(null);
      });

      final useCase = stopUseCase();
      await useCase(StopTimerParams(now: now));
      await useCase(StopTimerParams(now: now));
      await useCase(StopTimerParams(now: now));

      // Mesmo com 3 toques, o tempo entra só uma vez.
      verify(() => taskRepo.addSpentMinutes('t1', 40)).called(1);
      verify(() => entryRepo.add(any())).called(1);
    });

    test('parar um pausado limpa sem somar', () async {
      final active = ActiveTimerEntity(
        targetId: 't1',
        targetType: TimerTargetTypeEnum.task,
        listId: 'l1',
        startedAt: now.subtract(const Duration(minutes: 40)),
        status: TimerStatusEnum.paused,
      );
      when(() => timerRepo.claimActive())
          .thenAnswer((_) async => Right(active));

      final result = await stopUseCase()(StopTimerParams(now: now));

      expect(result.isRight(), isTrue);
      verifyNever(() => taskRepo.addSpentMinutes(any(), any()));
      verifyNever(() => entryRepo.add(any()));
    });

    test('falha ao somar não muda o resultado (claim já limpou)', () async {
      final active = ActiveTimerEntity(
        targetId: 't1',
        targetType: TimerTargetTypeEnum.task,
        listId: 'l1',
        startedAt: now.subtract(const Duration(minutes: 40)),
      );
      when(() => timerRepo.claimActive())
          .thenAnswer((_) async => Right(active));
      when(() => taskRepo.addSpentMinutes(any(), any()))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await stopUseCase()(StopTimerParams(now: now));

      expect(result.isRight(), isTrue);
      verify(() => entryRepo.add(any())).called(1);
    });
  });

  group('RegisterManualTimeUseCase', () {
    test('recusa não-folha', () async {
      final result = await manualUseCase()(
        RegisterManualTimeParams(
          targetId: 't1',
          targetIsLeaf: false,
          listId: 'l1',
          minutes: 30,
          now: now,
        ),
      );
      expect(result, isA<Left<Failure, Unit>>());
    });

    test('recusa duração <= 0 com InvalidDurationFailure', () async {
      final result = await manualUseCase()(
        RegisterManualTimeParams(
          targetId: 't1',
          targetIsLeaf: true,
          listId: 'l1',
          minutes: 0,
          now: now,
        ),
      );
      result.getLeft().fold(() => fail('esperava Left'),
          (f) => expect(f, isA<InvalidDurationFailure>()));
    });

    test('soma os minutos na folha e grava o registro', () async {
      await manualUseCase()(
        RegisterManualTimeParams(
          targetId: 't1',
          targetIsLeaf: true,
          listId: 'l1',
          minutes: 30,
          now: now,
        ),
      );

      verify(() => taskRepo.addSpentMinutes('t1', 30)).called(1);
      verify(() => entryRepo.add(any())).called(1);
    });
  });
}
