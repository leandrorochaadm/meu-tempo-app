import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/exceptions.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/data/datasources/timer_remote_data_source.dart';
import 'package:meu_tempo/features/task/data/models/active_timer_model.dart';
import 'package:meu_tempo/features/task/data/repositories/timer_repository_impl.dart';
import 'package:meu_tempo/features/task/domain/entities/active_timer_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements TimerRemoteDataSource {}

class _FakeModel extends Fake implements ActiveTimerModel {}

void main() {
  late _MockDataSource dataSource;
  late TimerRepositoryImpl repository;
  final startedAt = DateTime(2026, 7, 20, 10, 30);

  setUpAll(() => registerFallbackValue(_FakeModel()));

  setUp(() {
    dataSource = _MockDataSource();
    repository = TimerRepositoryImpl(dataSource);
  });

  ActiveTimerEntity entity(
    TimerStatusEnum status, {
    DateTime? at,
  }) =>
      ActiveTimerEntity(
        targetId: 't1',
        targetType: TimerTargetTypeEnum.task,
        listId: 'l1',
        startedAt: at ?? startedAt,
        status: status,
      );

  group('TimerRepositoryImpl', () {
    test('getActive converte status do model', () async {
      when(() => dataSource.getActive()).thenAnswer((_) async =>
          ActiveTimerModel.fromEntity(entity(TimerStatusEnum.paused)));

      final result = await repository.getActive();

      expect(result.getRight().toNullable()?.status, TimerStatusEnum.paused);
    });

    test('replaceActiveIfUnchanged: predicado aceita o doc igual ao esperado',
        () async {
      when(() => dataSource.replaceActiveIf(
            matches: any(named: 'matches'),
            replacement: any(named: 'replacement'),
          )).thenAnswer((_) async => true);
      final expected = entity(TimerStatusEnum.running);

      final result = await repository.replaceActiveIfUnchanged(
        expected: expected,
        replacement: entity(TimerStatusEnum.paused),
      );

      expect(result, const Right<Failure, bool>(true));
      final captured = verify(() => dataSource.replaceActiveIf(
            matches: captureAny(named: 'matches'),
            replacement: captureAny(named: 'replacement'),
          )).captured;
      final matches = captured[0] as bool Function(ActiveTimerModel?);
      final replacement = captured[1] as ActiveTimerModel;
      expect(replacement.status, TimerStatusEnum.paused.apiValue);
      expect(matches(ActiveTimerModel.fromEntity(expected)), isTrue);
      expect(
        matches(ActiveTimerModel.fromEntity(entity(
          TimerStatusEnum.running,
          at: startedAt.add(const Duration(minutes: 1)),
        ))),
        isFalse,
      );
      expect(
        matches(ActiveTimerModel.fromEntity(entity(TimerStatusEnum.paused))),
        isFalse,
      );
      expect(matches(null), isFalse);
    });

    test('replaceActiveIfUnchanged devolve Right(false) quando o datasource '
        'recusa', () async {
      when(() => dataSource.replaceActiveIf(
            matches: any(named: 'matches'),
            replacement: any(named: 'replacement'),
          )).thenAnswer((_) async => false);

      final result = await repository.replaceActiveIfUnchanged(
        expected: entity(TimerStatusEnum.running),
        replacement: entity(TimerStatusEnum.paused),
      );

      expect(result, const Right<Failure, bool>(false));
    });

    test('AppException vira Left(Failure)', () async {
      when(() => dataSource.replaceActiveIf(
            matches: any(named: 'matches'),
            replacement: any(named: 'replacement'),
          )).thenThrow(const ServerException());

      final result = await repository.replaceActiveIfUnchanged(
        expected: entity(TimerStatusEnum.running),
        replacement: entity(TimerStatusEnum.paused),
      );

      expect(result, const Left<Failure, bool>(ServerFailure()));
    });
  });
}
