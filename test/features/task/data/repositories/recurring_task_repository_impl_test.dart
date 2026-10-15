import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/exceptions.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/data/datasources/recurring_task_remote_data_source.dart';
import 'package:meu_tempo/features/task/data/models/recurring_task_model.dart';
import 'package:meu_tempo/features/task/data/repositories/recurring_task_repository_impl.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/recurring_task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/weekday_enum.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements RecurringTaskRemoteDataSource {}

class _FakeModel extends Fake implements RecurringTaskModel {}

void main() {
  late _MockDataSource dataSource;
  late RecurringTaskRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(_FakeModel()));

  setUp(() {
    dataSource = _MockDataSource();
    repository = RecurringTaskRepositoryImpl(dataSource);
  });

  RecurringTaskModel model({DateTime? lastGeneratedOn}) => RecurringTaskModel(
    id: 'r1',
    title: 'Academia',
    listId: 'l1',
    estimatedMinutes: 60,
    importance: ImportanceEnum.high,
    weekdays: const [WeekdayEnum.monday],
    createdAt: DateTime(2026, 10, 1),
    lastGeneratedOn: lastGeneratedOn,
  );

  RecurringTaskEntity entity() => model().toEntity();

  test('getAll should convert models to entities', () async {
    when(() => dataSource.getAll()).thenAnswer((_) async => [model()]);

    final result = await repository.getAll();

    expect(result.getRight().toNullable(), [entity()]);
  });

  test('claimGeneration should pass the bool through', () async {
    for (final value in [true, false]) {
      when(
        () => dataSource.claimGeneration(
          any(),
          any(),
          canClaim: any(named: 'canClaim'),
        ),
      ).thenAnswer((_) async => value);

      final result = await repository.claimGeneration(
        'r1',
        DateTime(2026, 10, 12),
      );

      expect(result, Right<Failure, bool>(value));
    }
  });

  test(
    'claimGeneration should refuse a template already generated that day',
    () async {
      when(
        () => dataSource.claimGeneration(
          any(),
          any(),
          canClaim: any(named: 'canClaim'),
        ),
      ).thenAnswer((_) async => true);

      await repository.claimGeneration('r1', DateTime(2026, 10, 12, 20));

      final canClaim =
          verify(
                () => dataSource.claimGeneration(
                  any(),
                  any(),
                  canClaim: captureAny(named: 'canClaim'),
                ),
              ).captured.single
              as bool Function(RecurringTaskModel);
      expect(canClaim(model(lastGeneratedOn: DateTime(2026, 10, 12))), isFalse);
      expect(canClaim(model(lastGeneratedOn: DateTime(2026, 10, 11))), isTrue);
      expect(canClaim(model()), isTrue);
    },
  );

  test('update should return Left(NotFoundFailure) when data source throws '
      'NotFoundException', () async {
    when(() => dataSource.update(any())).thenThrow(const NotFoundException());

    final result = await repository.update(entity());

    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
  });

  test(
    'watchAll should emit Left(ServerFailure) on unexpected error',
    () async {
      when(
        () => dataSource.watchAll(),
      ).thenAnswer((_) => Stream.error(Exception()));

      final result = await repository.watchAll().first;

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    },
  );

  test(
    'getAll should return Left(ServerFailure) on unexpected error',
    () async {
      when(() => dataSource.getAll()).thenThrow(ArgumentError());

      final result = await repository.getAll();

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    },
  );
}
