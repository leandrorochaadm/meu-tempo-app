import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/appointment/domain/repositories/appointment_repository.dart';
import 'package:meu_tempo/features/task/domain/entities/active_timer_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_origin_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart';
import 'package:meu_tempo/features/task/domain/repositories/time_entry_repository.dart';
import 'package:meu_tempo/features/task/domain/usecases/record_timer_session_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepo extends Mock implements TaskRepository {}

class _MockAppointmentRepo extends Mock implements AppointmentRepository {}

class _MockTimeEntryRepo extends Mock implements TimeEntryRepository {}

class _FakeTimeEntry extends Fake implements TimeEntryEntity {}

void main() {
  late _MockTaskRepo taskRepo;
  late _MockAppointmentRepo apptRepo;
  late _MockTimeEntryRepo entryRepo;
  late RecordTimerSessionUseCase useCase;
  final now = DateTime(2026, 7, 20, 10, 30);

  setUpAll(() => registerFallbackValue(_FakeTimeEntry()));

  setUp(() {
    taskRepo = _MockTaskRepo();
    apptRepo = _MockAppointmentRepo();
    entryRepo = _MockTimeEntryRepo();
    when(
      () => taskRepo.addSpentMinutes(any(), any()),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => apptRepo.addSpentMinutes(any(), any()),
    ).thenAnswer((_) async => const Right(unit));
    when(() => entryRepo.add(any())).thenAnswer((_) async => const Right(unit));
    useCase = RecordTimerSessionUseCase(taskRepo, apptRepo, entryRepo);
  });

  ActiveTimerEntity session({
    TimerTargetTypeEnum type = TimerTargetTypeEnum.task,
    String id = 't1',
    int minutes = 30,
    TimerStatusEnum status = TimerStatusEnum.running,
  }) => ActiveTimerEntity(
    targetId: id,
    targetType: type,
    listId: 'l1',
    startedAt: now.subtract(Duration(minutes: minutes)),
    status: status,
  );

  void expectNothingCalled() {
    verifyNever(() => taskRepo.addSpentMinutes(any(), any()));
    verifyNever(() => apptRepo.addSpentMinutes(any(), any()));
    verifyNever(() => entryRepo.add(any()));
  }

  group('RecordTimerSessionUseCase', () {
    test('tarefa: soma na tarefa e grava registro com origem timer', () async {
      final result = await useCase(
        RecordTimerSessionParams(session: session(), now: now),
      );

      expect(result.isRight(), isTrue);
      verify(() => taskRepo.addSpentMinutes('t1', 30)).called(1);
      verifyNever(() => apptRepo.addSpentMinutes(any(), any()));
      final entry =
          verify(() => entryRepo.add(captureAny())).captured.single
              as TimeEntryEntity;
      expect(entry.minutes, 30);
      expect(entry.origin, TimeEntryOriginEnum.timer);
      expect(entry.occurredAt, now);
      expect(entry.listId, 'l1');
    });

    test('compromisso: soma no repositório de compromisso', () async {
      await useCase(
        RecordTimerSessionParams(
          session: session(
            type: TimerTargetTypeEnum.appointment,
            id: 'a1',
            minutes: 10,
          ),
          now: now,
        ),
      );

      verify(() => apptRepo.addSpentMinutes('a1', 10)).called(1);
      verifyNever(() => taskRepo.addSpentMinutes(any(), any()));
    });

    test('sessão de 0 minuto não grava nada', () async {
      final result = await useCase(
        RecordTimerSessionParams(session: session(minutes: 0), now: now),
      );

      expect(result.isRight(), isTrue);
      expectNothingCalled();
    });

    test('cronômetro pausado não grava nada', () async {
      await useCase(
        RecordTimerSessionParams(
          session: session(minutes: 40, status: TimerStatusEnum.paused),
          now: now,
        ),
      );

      expectNothingCalled();
    });

    test('falha ao somar devolve Left e ainda grava o registro', () async {
      when(
        () => taskRepo.addSpentMinutes(any(), any()),
      ).thenAnswer((_) async => const Left(ServerFailure()));

      final result = await useCase(
        RecordTimerSessionParams(session: session(), now: now),
      );

      expect(result, const Left<Failure, Unit>(ServerFailure()));
      verify(() => entryRepo.add(any())).called(1);
    });

    test('falha ao gravar o registro devolve Left', () async {
      when(
        () => entryRepo.add(any()),
      ).thenAnswer((_) async => const Left(ServerFailure()));

      final result = await useCase(
        RecordTimerSessionParams(session: session(), now: now),
      );

      expect(result, const Left<Failure, Unit>(ServerFailure()));
    });
  });
}
