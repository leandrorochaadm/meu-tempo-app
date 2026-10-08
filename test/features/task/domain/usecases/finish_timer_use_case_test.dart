import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/appointment/domain/repositories/appointment_repository.dart';
import 'package:meu_tempo/features/appointment/domain/usecases/set_appointment_done_use_case.dart';
import 'package:meu_tempo/features/task/domain/entities/active_timer_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart';
import 'package:meu_tempo/features/task/domain/repositories/time_entry_repository.dart';
import 'package:meu_tempo/features/task/domain/repositories/timer_repository.dart';
import 'package:meu_tempo/features/task/domain/usecases/complete_task_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/finish_timer_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/record_timer_session_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockTimerRepo extends Mock implements TimerRepository {}

class _MockTaskRepo extends Mock implements TaskRepository {}

class _MockAppointmentRepo extends Mock implements AppointmentRepository {}

class _MockTimeEntryRepo extends Mock implements TimeEntryRepository {}

class _MockCompleteTask extends Mock implements CompleteTaskUseCase {}

class _MockSetAppointmentDone extends Mock
    implements SetAppointmentDoneUseCase {}

class _FakeActiveTimer extends Fake implements ActiveTimerEntity {}

class _FakeTimeEntry extends Fake implements TimeEntryEntity {}

void main() {
  late _MockTimerRepo timerRepo;
  late _MockTaskRepo taskRepo;
  late _MockAppointmentRepo apptRepo;
  late _MockTimeEntryRepo entryRepo;
  late _MockCompleteTask completeTask;
  late _MockSetAppointmentDone setAppointmentDone;
  final now = DateTime(2026, 10, 7, 15);

  setUpAll(() {
    registerFallbackValue(_FakeActiveTimer());
    registerFallbackValue(_FakeTimeEntry());
    registerFallbackValue(const CompleteTaskParams(taskId: 'x', done: true));
    registerFallbackValue(
      const SetAppointmentDoneParams(appointmentId: 'x', done: true),
    );
  });

  setUp(() {
    timerRepo = _MockTimerRepo();
    taskRepo = _MockTaskRepo();
    apptRepo = _MockAppointmentRepo();
    entryRepo = _MockTimeEntryRepo();
    completeTask = _MockCompleteTask();
    setAppointmentDone = _MockSetAppointmentDone();
    when(
      () => taskRepo.addSpentMinutes(any(), any()),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => apptRepo.addSpentMinutes(any(), any()),
    ).thenAnswer((_) async => const Right(unit));
    when(() => entryRepo.add(any())).thenAnswer((_) async => const Right(unit));
    when(() => completeTask(any())).thenAnswer((_) async => const Right(unit));
    when(
      () => setAppointmentDone(any()),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => timerRepo.clearActiveIfUnchanged(expected: any(named: 'expected')),
    ).thenAnswer((_) async => const Right(true));
  });

  FinishTimerUseCase build() => FinishTimerUseCase(
    timerRepo,
    RecordTimerSessionUseCase(taskRepo, apptRepo, entryRepo),
    completeTask,
    setAppointmentDone,
  );

  ActiveTimerEntity running(String id, TimerTargetTypeEnum type) =>
      ActiveTimerEntity(
        targetId: id,
        targetType: type,
        listId: 'l1',
        startedAt: now.subtract(const Duration(minutes: 25)),
      );

  ActiveTimerEntity paused(String id, TimerTargetTypeEnum type) =>
      ActiveTimerEntity(
        targetId: id,
        targetType: type,
        listId: 'l1',
        startedAt: now.subtract(const Duration(minutes: 40)),
        status: TimerStatusEnum.paused,
      );

  void givenActive(ActiveTimerEntity? active) =>
      when(() => timerRepo.getActive()).thenAnswer((_) async => Right(active));

  Future<Either<Failure, Unit>> finish(String id) =>
      build()(FinishTimerParams(targetId: id, now: now));

  void verifyNothingWritten() {
    verifyNever(() => taskRepo.addSpentMinutes(any(), any()));
    verifyNever(() => apptRepo.addSpentMinutes(any(), any()));
    verifyNever(() => entryRepo.add(any()));
    verifyNever(() => completeTask(any()));
    verifyNever(() => setAppointmentDone(any()));
  }

  group('FinishTimerUseCase', () {
    test('tarefa rodando: limpa, soma a sessão e conclui a folha', () async {
      final active = running('t1', TimerTargetTypeEnum.task);
      givenActive(active);

      final result = await finish('t1');

      expect(result, const Right<Failure, Unit>(unit));
      verify(
        () => timerRepo.clearActiveIfUnchanged(expected: active),
      ).called(1);
      verify(() => taskRepo.addSpentMinutes('t1', 25)).called(1);
      final entry =
          verify(() => entryRepo.add(captureAny())).captured.single
              as TimeEntryEntity;
      expect(entry.minutes, 25);
      verify(
        () => completeTask(const CompleteTaskParams(taskId: 't1', done: true)),
      ).called(1);
      verifyNever(() => setAppointmentDone(any()));
    });

    test(
      'compromisso rodando: soma no compromisso e marca como feito',
      () async {
        givenActive(running('a1', TimerTargetTypeEnum.appointment));

        final result = await finish('a1');

        expect(result, const Right<Failure, Unit>(unit));
        verify(() => apptRepo.addSpentMinutes('a1', 25)).called(1);
        verify(
          () => setAppointmentDone(
            const SetAppointmentDoneParams(appointmentId: 'a1', done: true),
          ),
        ).called(1);
        verifyNever(() => completeTask(any()));
      },
    );

    test('tarefa pausada: limpa e conclui sem somar', () async {
      givenActive(paused('t1', TimerTargetTypeEnum.task));

      final result = await finish('t1');

      expect(result, const Right<Failure, Unit>(unit));
      verifyNever(() => taskRepo.addSpentMinutes(any(), any()));
      verifyNever(() => entryRepo.add(any()));
      verify(() => completeTask(any())).called(1);
    });

    test('compromisso pausado: limpa e marca como feito sem somar', () async {
      givenActive(paused('a1', TimerTargetTypeEnum.appointment));

      final result = await finish('a1');

      expect(result, const Right<Failure, Unit>(unit));
      verifyNever(() => apptRepo.addSpentMinutes(any(), any()));
      verifyNever(() => entryRepo.add(any()));
      verify(() => setAppointmentDone(any())).called(1);
    });

    test('outro alvo ativo: no-op', () async {
      givenActive(running('t2', TimerTargetTypeEnum.task));

      final result = await finish('t1');

      expect(result, const Right<Failure, Unit>(unit));
      verifyNever(
        () =>
            timerRepo.clearActiveIfUnchanged(expected: any(named: 'expected')),
      );
      verifyNothingWritten();
    });

    test('sem cronômetro: no-op', () async {
      givenActive(null);

      final result = await finish('t1');

      expect(result, const Right<Failure, Unit>(unit));
      verifyNever(
        () =>
            timerRepo.clearActiveIfUnchanged(expected: any(named: 'expected')),
      );
      verifyNothingWritten();
    });

    test('corrida perdida (limpeza recusada): não soma nem conclui', () async {
      givenActive(running('t1', TimerTargetTypeEnum.task));
      when(
        () =>
            timerRepo.clearActiveIfUnchanged(expected: any(named: 'expected')),
      ).thenAnswer((_) async => const Right(false));

      final result = await finish('t1');

      expect(result, const Right<Failure, Unit>(unit));
      verifyNothingWritten();
    });

    test('idempotente: dois parar seguidos concluem uma vez só', () async {
      final answers = <ActiveTimerEntity?>[
        running('t1', TimerTargetTypeEnum.task),
        null,
      ];
      when(
        () => timerRepo.getActive(),
      ).thenAnswer((_) async => Right(answers.removeAt(0)));
      final useCase = build();

      await useCase(FinishTimerParams(targetId: 't1', now: now));
      await useCase(FinishTimerParams(targetId: 't1', now: now));

      verify(() => completeTask(any())).called(1);
      verify(() => taskRepo.addSpentMinutes('t1', 25)).called(1);
    });

    test('falha ao ler o cronômetro devolve Left sem agir', () async {
      when(
        () => timerRepo.getActive(),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await finish('t1');

      expect(result, const Left<Failure, Unit>(NetworkFailure()));
      verifyNothingWritten();
    });

    test('falha ao limpar devolve Left sem somar nem concluir', () async {
      givenActive(running('t1', TimerTargetTypeEnum.task));
      when(
        () =>
            timerRepo.clearActiveIfUnchanged(expected: any(named: 'expected')),
      ).thenAnswer((_) async => const Left(ServerFailure()));

      final result = await finish('t1');

      expect(result, const Left<Failure, Unit>(ServerFailure()));
      verifyNothingWritten();
    });

    test('falha ao somar ainda conclui e devolve a falha', () async {
      givenActive(running('t1', TimerTargetTypeEnum.task));
      when(
        () => taskRepo.addSpentMinutes(any(), any()),
      ).thenAnswer((_) async => const Left(ServerFailure()));

      final result = await finish('t1');

      expect(result, const Left<Failure, Unit>(ServerFailure()));
      verify(() => completeTask(any())).called(1);
    });

    test('compromisso apagado devolve NotFoundFailure', () async {
      givenActive(running('a1', TimerTargetTypeEnum.appointment));
      when(
        () => setAppointmentDone(any()),
      ).thenAnswer((_) async => const Left(NotFoundFailure()));

      final result = await finish('a1');

      expect(result, const Left<Failure, Unit>(NotFoundFailure()));
      verify(
        () =>
            timerRepo.clearActiveIfUnchanged(expected: any(named: 'expected')),
      ).called(1);
    });

    test('Params com mesmos valores são iguais', () {
      expect(
        FinishTimerParams(targetId: 't1', now: now),
        FinishTimerParams(targetId: 't1', now: now),
      );
    });
  });
}
