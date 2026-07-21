import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_origin_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart';
import 'package:meu_tempo/features/task/domain/repositories/time_entry_repository.dart';
import 'package:meu_tempo/features/task/domain/task_failures.dart';
import 'package:meu_tempo/features/task/domain/usecases/delete_time_entry_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/update_time_entry_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepo extends Mock implements TaskRepository {}

class _MockTimeEntryRepo extends Mock implements TimeEntryRepository {}

class _FakeTimeEntry extends Fake implements TimeEntryEntity {}

void main() {
  late _MockTaskRepo taskRepo;
  late _MockTimeEntryRepo entryRepo;
  final occurredAt = DateTime(2026, 7, 20, 9);

  TimeEntryEntity entry({int minutes = 30}) => TimeEntryEntity(
        id: 'e1',
        targetId: 't1',
        targetType: TimerTargetTypeEnum.task,
        listId: 'l1',
        minutes: minutes,
        origin: TimeEntryOriginEnum.manual,
        occurredAt: occurredAt,
      );

  setUpAll(() => registerFallbackValue(_FakeTimeEntry()));

  setUp(() {
    taskRepo = _MockTaskRepo();
    entryRepo = _MockTimeEntryRepo();
    when(() => taskRepo.addSpentMinutes(any(), any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => entryRepo.update(any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => entryRepo.delete(any()))
        .thenAnswer((_) async => const Right(unit));
  });

  group('UpdateTimeEntryUseCase', () {
    UpdateTimeEntryUseCase useCase() =>
        UpdateTimeEntryUseCase(entryRepo, taskRepo);

    test('minutos <= 0 retorna InvalidDurationFailure', () async {
      final r = await useCase()(UpdateTimeEntryParams(
        original: entry(minutes: 30),
        newMinutes: 0,
        newOccurredAt: occurredAt,
      ));
      r.getLeft().fold(() => fail('esperava Left'),
          (f) => expect(f, isA<InvalidDurationFailure>()));
      verifyNever(() => entryRepo.update(any()));
    });

    test('aumentar minutos ajusta o acumulado por delta positivo', () async {
      await useCase()(UpdateTimeEntryParams(
        original: entry(minutes: 30),
        newMinutes: 50,
        newOccurredAt: occurredAt,
      ));
      verify(() => taskRepo.addSpentMinutes('t1', 20)).called(1);
    });

    test('reduzir minutos ajusta o acumulado por delta negativo', () async {
      await useCase()(UpdateTimeEntryParams(
        original: entry(minutes: 30),
        newMinutes: 10,
        newOccurredAt: occurredAt,
      ));
      verify(() => taskRepo.addSpentMinutes('t1', -20)).called(1);
    });

    test('preserva origin/targetType/listId/id do registro original', () async {
      await useCase()(UpdateTimeEntryParams(
        original: entry(minutes: 30),
        newMinutes: 45,
        newOccurredAt: occurredAt,
      ));
      final captured = verify(() => entryRepo.update(captureAny()))
          .captured
          .single as TimeEntryEntity;
      expect(captured.id, 'e1');
      expect(captured.origin, TimeEntryOriginEnum.manual);
      expect(captured.targetType, TimerTargetTypeEnum.task);
      expect(captured.listId, 'l1');
      expect(captured.minutes, 45);
    });

    test('delta zero não chama addSpentMinutes', () async {
      await useCase()(UpdateTimeEntryParams(
        original: entry(minutes: 30),
        newMinutes: 30,
        newOccurredAt: occurredAt,
      ));
      verifyNever(() => taskRepo.addSpentMinutes(any(), any()));
    });
  });

  group('DeleteTimeEntryUseCase', () {
    DeleteTimeEntryUseCase useCase() =>
        DeleteTimeEntryUseCase(entryRepo, taskRepo);

    test('exclui e desconta os minutos do acumulado', () async {
      await useCase()(DeleteTimeEntryParams(entry: entry(minutes: 25)));
      verify(() => entryRepo.delete('e1')).called(1);
      verify(() => taskRepo.addSpentMinutes('t1', -25)).called(1);
    });

    test('falha do repo propaga Left e não ajusta o acumulado', () async {
      when(() => entryRepo.delete(any()))
          .thenAnswer((_) async => const Left(ServerFailure()));
      final r = await useCase()(DeleteTimeEntryParams(entry: entry()));
      expect(r, isA<Left<Failure, Unit>>());
      verifyNever(() => taskRepo.addSpentMinutes(any(), any()));
    });
  });
}
