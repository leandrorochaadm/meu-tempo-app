import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/recurring_task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/weekday_enum.dart';
import 'package:meu_tempo/features/task/domain/repositories/recurring_task_repository.dart';
import 'package:meu_tempo/features/task/domain/task_failures.dart';
import 'package:meu_tempo/features/task/domain/usecases/create_recurring_task_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockRecurringTaskRepository extends Mock
    implements RecurringTaskRepository {}

class _FakeRecurringTaskEntity extends Fake implements RecurringTaskEntity {}

void main() {
  late _MockRecurringTaskRepository repository;
  late CreateRecurringTaskUseCase useCase;
  final now = DateTime(2026, 10, 12, 9, 30);

  CreateRecurringTaskParams params({
    String title = '  Academia ',
    int minutes = 60,
    Set<WeekdayEnum> weekdays = const {
      WeekdayEnum.monday,
      WeekdayEnum.wednesday,
    },
  }) => CreateRecurringTaskParams(
    title: title,
    listId: 'inbox',
    estimatedMinutes: minutes,
    importance: ImportanceEnum.values.first,
    weekdays: weekdays,
    now: now,
  );

  setUpAll(() => registerFallbackValue(_FakeRecurringTaskEntity()));

  setUp(() {
    repository = _MockRecurringTaskRepository();
    useCase = CreateRecurringTaskUseCase(repository);
  });

  test('should create', () async {
    when(() => repository.create(any())).thenAnswer(
      (inv) async =>
          Right(inv.positionalArguments.first as RecurringTaskEntity),
    );

    final result = await useCase(params());

    final captured =
        verify(() => repository.create(captureAny())).captured.single
            as RecurringTaskEntity;
    expect(captured.id, '');
    expect(captured.title, 'Academia');
    expect(captured.createdAt, now);
    expect(captured.lastGeneratedOn, isNull);
    expect(captured.weekdays, {WeekdayEnum.monday, WeekdayEnum.wednesday});
    expect(captured.listId, 'inbox');
    expect(captured.estimatedMinutes, 60);
    expect(captured.importance, ImportanceEnum.values.first);
    expect(result, Right<Failure, RecurringTaskEntity>(captured));
  });

  test('should create without weekdays (sem dia fixo)', () async {
    when(() => repository.create(any())).thenAnswer(
      (inv) async =>
          Right(inv.positionalArguments.first as RecurringTaskEntity),
    );

    final result = await useCase(params(weekdays: const {}));

    expect(result.isRight(), isTrue);
    verify(() => repository.create(any())).called(1);
  });

  test('should fail with EmptyTitleFailure when title is blank', () async {
    final result = await useCase(params(title: '   '));

    expect(
      result,
      const Left<Failure, RecurringTaskEntity>(EmptyTitleFailure()),
    );
    verifyNever(() => repository.create(any()));
  });

  test('should fail with InvalidDurationFailure when minutes <= 0', () async {
    for (final minutes in [0, -5]) {
      final result = await useCase(params(minutes: minutes));

      expect(
        result,
        const Left<Failure, RecurringTaskEntity>(InvalidDurationFailure()),
      );
    }
    verifyNever(() => repository.create(any()));
  });

  test('should return repository failure', () async {
    when(
      () => repository.create(any()),
    ).thenAnswer((_) async => const Left(ServerFailure()));

    final result = await useCase(params());

    expect(result, const Left<Failure, RecurringTaskEntity>(ServerFailure()));
  });
}
