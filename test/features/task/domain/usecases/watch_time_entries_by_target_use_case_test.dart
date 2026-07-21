import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_origin_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:meu_tempo/features/task/domain/repositories/time_entry_repository.dart';
import 'package:meu_tempo/features/task/domain/usecases/watch_time_entries_by_target_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements TimeEntryRepository {}

void main() {
  late _MockRepo repo;

  final entry = TimeEntryEntity(
    id: 'e1',
    targetId: 't1',
    targetType: TimerTargetTypeEnum.task,
    listId: 'l1',
    minutes: 30,
    origin: TimeEntryOriginEnum.manual,
    occurredAt: DateTime(2026, 7, 10),
  );

  setUp(() => repo = _MockRepo());

  test('delega ao repositório passando o targetId', () async {
    when(() => repo.watchByTarget('t1'))
        .thenAnswer((_) => Stream.value(Right([entry])));

    final result = await WatchTimeEntriesByTargetUseCase(repo)(
      const WatchTimeEntriesByTargetParams(targetId: 't1'),
    ).first;

    expect(result.getRight().toNullable()!.single.id, 'e1');
    verify(() => repo.watchByTarget('t1')).called(1);
  });

  test('propaga Left do repositório', () async {
    when(() => repo.watchByTarget('t1'))
        .thenAnswer((_) => Stream.value(const Left(ServerFailure())));

    final result = await WatchTimeEntriesByTargetUseCase(repo)(
      const WatchTimeEntriesByTargetParams(targetId: 't1'),
    ).first;

    expect(result.isLeft(), isTrue);
  });
}
