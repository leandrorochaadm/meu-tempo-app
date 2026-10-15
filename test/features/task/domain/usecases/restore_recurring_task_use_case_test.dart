import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/recurring_task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/weekday_enum.dart';
import 'package:meu_tempo/features/task/domain/repositories/recurring_task_repository.dart';
import 'package:meu_tempo/features/task/domain/usecases/restore_recurring_task_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockRecurringTaskRepository extends Mock
    implements RecurringTaskRepository {}

class _FakeRecurringTaskEntity extends Fake implements RecurringTaskEntity {}

void main() {
  late _MockRecurringTaskRepository repository;
  late RestoreRecurringTaskUseCase useCase;

  final template = RecurringTaskEntity(
    id: 'r1',
    title: 'Academia',
    listId: 'inbox',
    estimatedMinutes: 60,
    importance: ImportanceEnum.values.first,
    weekdays: const {WeekdayEnum.monday},
    createdAt: DateTime(2026, 10, 1),
    lastGeneratedOn: DateTime(2026, 10, 12),
  );

  setUpAll(() => registerFallbackValue(_FakeRecurringTaskEntity()));

  setUp(() {
    repository = _MockRecurringTaskRepository();
    useCase = RestoreRecurringTaskUseCase(repository);
  });

  test('should restore the same template', () async {
    when(() => repository.restore(any())).thenAnswer((_) async => Right(unit));

    final result = await useCase(
      RestoreRecurringTaskParams(template: template),
    );

    expect(result, Right<Failure, Unit>(unit));
    final captured =
        verify(() => repository.restore(captureAny())).captured.single
            as RecurringTaskEntity;
    expect(captured, template);
    expect(captured.id, 'r1');
    expect(captured.lastGeneratedOn, DateTime(2026, 10, 12));
  });

  test('should return repository failure', () async {
    when(
      () => repository.restore(any()),
    ).thenAnswer((_) async => const Left(ServerFailure()));

    final result = await useCase(
      RestoreRecurringTaskParams(template: template),
    );

    expect(result, const Left<Failure, Unit>(ServerFailure()));
  });
}
