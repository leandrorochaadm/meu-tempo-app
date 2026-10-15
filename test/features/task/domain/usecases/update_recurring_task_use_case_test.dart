import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/recurring_task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/weekday_enum.dart';
import 'package:meu_tempo/features/task/domain/repositories/recurring_task_repository.dart';
import 'package:meu_tempo/features/task/domain/task_failures.dart';
import 'package:meu_tempo/features/task/domain/usecases/update_recurring_task_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockRecurringTaskRepository extends Mock
    implements RecurringTaskRepository {}

class _FakeRecurringTaskEntity extends Fake implements RecurringTaskEntity {}

void main() {
  late _MockRecurringTaskRepository repository;
  late UpdateRecurringTaskUseCase useCase;

  final original = RecurringTaskEntity(
    id: 'r1',
    title: 'Antigo',
    listId: 'inbox',
    estimatedMinutes: 30,
    importance: ImportanceEnum.values.first,
    weekdays: const {WeekdayEnum.friday},
    createdAt: DateTime(2026, 10, 1),
    lastGeneratedOn: DateTime(2026, 10, 12),
  );

  UpdateRecurringTaskParams params({
    String title = '  Academia ',
    int minutes = 60,
  }) => UpdateRecurringTaskParams(
    original: original,
    title: title,
    listId: 'work',
    estimatedMinutes: minutes,
    importance: ImportanceEnum.values.last,
    weekdays: const {WeekdayEnum.monday, WeekdayEnum.wednesday},
  );

  setUpAll(() => registerFallbackValue(_FakeRecurringTaskEntity()));

  setUp(() {
    repository = _MockRecurringTaskRepository();
    useCase = UpdateRecurringTaskUseCase(repository);
  });

  test('should keep createdAt and lastGeneratedOn', () async {
    when(() => repository.update(any())).thenAnswer(
      (inv) async =>
          Right(inv.positionalArguments.first as RecurringTaskEntity),
    );

    final result = await useCase(params());

    final captured =
        verify(() => repository.update(captureAny())).captured.single
            as RecurringTaskEntity;
    expect(captured.id, 'r1');
    expect(captured.createdAt, DateTime(2026, 10, 1));
    expect(captured.lastGeneratedOn, DateTime(2026, 10, 12));
    expect(captured.title, 'Academia');
    expect(captured.listId, 'work');
    expect(captured.estimatedMinutes, 60);
    expect(captured.importance, ImportanceEnum.values.last);
    expect(captured.weekdays, {WeekdayEnum.monday, WeekdayEnum.wednesday});
    expect(result, Right<Failure, RecurringTaskEntity>(captured));
  });

  test('should fail with EmptyTitleFailure', () async {
    final result = await useCase(params(title: '  '));

    expect(
      result,
      const Left<Failure, RecurringTaskEntity>(EmptyTitleFailure()),
    );
    verifyNever(() => repository.update(any()));
  });

  test('should fail with InvalidDurationFailure when minutes <= 0', () async {
    final result = await useCase(params(minutes: 0));

    expect(
      result,
      const Left<Failure, RecurringTaskEntity>(InvalidDurationFailure()),
    );
    verifyNever(() => repository.update(any()));
  });

  test('should return repository failure', () async {
    when(
      () => repository.update(any()),
    ).thenAnswer((_) async => const Left(ServerFailure()));

    final result = await useCase(params());

    expect(result, const Left<Failure, RecurringTaskEntity>(ServerFailure()));
  });
}
