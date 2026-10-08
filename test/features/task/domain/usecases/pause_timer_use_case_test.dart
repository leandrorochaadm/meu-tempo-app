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
import 'package:meu_tempo/features/task/domain/usecases/pause_timer_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/record_timer_session_use_case.dart';
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
  late PauseTimerUseCase useCase;
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
    when(() => timerRepo.replaceActiveIfUnchanged(
          expected: any(named: 'expected'),
          replacement: any(named: 'replacement'),
        )).thenAnswer((_) async => const Right(true));
    useCase = PauseTimerUseCase(
      timerRepo,
      RecordTimerSessionUseCase(taskRepo, apptRepo, entryRepo),
    );
  });

  ActiveTimerEntity active({
    String id = 't1',
    TimerTargetTypeEnum type = TimerTargetTypeEnum.task,
    int minutes = 25,
    TimerStatusEnum status = TimerStatusEnum.running,
  }) =>
      ActiveTimerEntity(
        targetId: id,
        targetType: type,
        listId: 'l1',
        startedAt: now.subtract(Duration(minutes: minutes)),
        status: status,
      );

  void stubActive(ActiveTimerEntity? timer) =>
      when(() => timerRepo.getActive()).thenAnswer((_) async => Right(timer));

  PauseTimerParams params() => PauseTimerParams(targetId: 't1', now: now);

  void expectNoWrites() {
    verifyNever(() => timerRepo.replaceActiveIfUnchanged(
          expected: any(named: 'expected'),
          replacement: any(named: 'replacement'),
        ));
    verifyNever(() => taskRepo.addSpentMinutes(any(), any()));
    verifyNever(() => apptRepo.addSpentMinutes(any(), any()));
    verifyNever(() => entryRepo.add(any()));
  }

  group('PauseTimerUseCase', () {
    test('pausa a tarefa rodando: soma a sessão e grava como pausado',
        () async {
      final running = active();
      stubActive(running);

      final result = await useCase(params());

      expect(result, const Right<Failure, Unit>(unit));
      final captured = verify(() => timerRepo.replaceActiveIfUnchanged(
            expected: captureAny(named: 'expected'),
            replacement: captureAny(named: 'replacement'),
          )).captured;
      expect(captured[0], running);
      final replacement = captured[1] as ActiveTimerEntity;
      expect(replacement.status, TimerStatusEnum.paused);
      expect(replacement.startedAt, now);
      expect(replacement.targetId, running.targetId);
      expect(replacement.targetType, running.targetType);
      expect(replacement.listId, running.listId);
      verify(() => taskRepo.addSpentMinutes('t1', 25)).called(1);
      verify(() => entryRepo.add(any())).called(1);
    });

    test('pausa o compromisso rodando somando no repositório de compromisso',
        () async {
      stubActive(active(
        id: 't1',
        type: TimerTargetTypeEnum.appointment,
        minutes: 10,
      ));

      await useCase(params());

      verify(() => apptRepo.addSpentMinutes('t1', 10)).called(1);
      verifyNever(() => taskRepo.addSpentMinutes(any(), any()));
    });

    test('já pausado: no-op', () async {
      stubActive(active(status: TimerStatusEnum.paused));

      final result = await useCase(params());

      expect(result.isRight(), isTrue);
      expectNoWrites();
    });

    test('outro alvo ativo: no-op', () async {
      stubActive(active(id: 't2'));

      final result = await useCase(params());

      expect(result.isRight(), isTrue);
      expectNoWrites();
    });

    test('sem cronômetro: no-op', () async {
      stubActive(null);

      final result = await useCase(params());

      expect(result.isRight(), isTrue);
      expectNoWrites();
    });

    test('corrida perdida (troca recusada): não soma', () async {
      stubActive(active());
      when(() => timerRepo.replaceActiveIfUnchanged(
            expected: any(named: 'expected'),
            replacement: any(named: 'replacement'),
          )).thenAnswer((_) async => const Right(false));

      final result = await useCase(params());

      expect(result, const Right<Failure, Unit>(unit));
      verifyNever(() => taskRepo.addSpentMinutes(any(), any()));
      verifyNever(() => entryRepo.add(any()));
    });

    test('idempotente: dois pausar seguidos somam uma vez só', () async {
      var reads = 0;
      when(() => timerRepo.getActive()).thenAnswer((_) async {
        reads++;
        return Right(
          reads == 1 ? active() : active(status: TimerStatusEnum.paused),
        );
      });

      await useCase(params());
      await useCase(params());

      verify(() => taskRepo.addSpentMinutes('t1', 25)).called(1);
    });

    test('falha ao ler o cronômetro devolve Left', () async {
      when(() => timerRepo.getActive())
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await useCase(params());

      expect(result, const Left<Failure, Unit>(ServerFailure()));
      expectNoWrites();
    });

    test('falha na troca devolve Left sem somar', () async {
      stubActive(active());
      when(() => timerRepo.replaceActiveIfUnchanged(
            expected: any(named: 'expected'),
            replacement: any(named: 'replacement'),
          )).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await useCase(params());

      expect(result, const Left<Failure, Unit>(NetworkFailure()));
      verifyNever(() => taskRepo.addSpentMinutes(any(), any()));
      verifyNever(() => entryRepo.add(any()));
    });

    test('Params com mesmos valores são iguais', () {
      expect(params(), PauseTimerParams(targetId: 't1', now: now));
    });
  });
}
