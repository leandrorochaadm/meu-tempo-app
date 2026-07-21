import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/exceptions.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/data/datasources/time_entry_remote_data_source.dart';
import 'package:meu_tempo/features/task/data/models/time_entry_model.dart';
import 'package:meu_tempo/features/task/data/repositories/time_entry_repository_impl.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_origin_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements TimeEntryRemoteDataSource {}

class _FakeModel extends Fake implements TimeEntryModel {}

void main() {
  late _MockDataSource dataSource;
  late TimeEntryRepositoryImpl repository;

  final model = TimeEntryModel(
    id: 'e1',
    targetId: 't1',
    targetType: TimerTargetTypeEnum.task,
    listId: 'l1',
    minutes: 30,
    origin: TimeEntryOriginEnum.manual,
    occurredAt: DateTime(2026, 7, 10),
  );

  final entity = TimeEntryEntity(
    id: 'e1',
    targetId: 't1',
    targetType: TimerTargetTypeEnum.task,
    listId: 'l1',
    minutes: 30,
    origin: TimeEntryOriginEnum.manual,
    occurredAt: DateTime(2026, 7, 10),
  );

  setUpAll(() => registerFallbackValue(_FakeModel()));

  setUp(() {
    dataSource = _MockDataSource();
    repository = TimeEntryRepositoryImpl(dataSource);
  });

  group('watchByTarget', () {
    test('converte Model → Entity no sucesso', () async {
      when(() => dataSource.watchByTarget('t1'))
          .thenAnswer((_) => Stream.value([model]));

      final result = await repository.watchByTarget('t1').first;

      expect(result.isRight(), isTrue);
      final list = result.getRight().toNullable()!;
      expect(list, isA<List<TimeEntryEntity>>());
      expect(list.single.id, 'e1');
    });

    test('mapeia AppException → Failure', () async {
      when(() => dataSource.watchByTarget('t1'))
          .thenThrow(const ServerException());

      final result = await repository.watchByTarget('t1').first;

      expect(result,
          const Left<Failure, List<TimeEntryEntity>>(ServerFailure()));
    });
  });

  group('update', () {
    test('delega ao datasource e retorna Right no sucesso', () async {
      when(() => dataSource.update(any())).thenAnswer((_) async {});

      final result = await repository.update(entity);

      expect(result.isRight(), isTrue);
      verify(() => dataSource.update(any())).called(1);
    });

    test('AppException vira Left(Failure)', () async {
      when(() => dataSource.update(any())).thenThrow(const ServerException());

      final result = await repository.update(entity);

      expect(result, const Left<Failure, Unit>(ServerFailure()));
    });
  });

  group('delete', () {
    test('delega ao datasource e retorna Right no sucesso', () async {
      when(() => dataSource.delete('e1')).thenAnswer((_) async {});

      final result = await repository.delete('e1');

      expect(result.isRight(), isTrue);
      verify(() => dataSource.delete('e1')).called(1);
    });

    test('AppException vira Left(Failure)', () async {
      when(() => dataSource.delete('e1')).thenThrow(const ServerException());

      final result = await repository.delete('e1');

      expect(result, const Left<Failure, Unit>(ServerFailure()));
    });
  });
}
