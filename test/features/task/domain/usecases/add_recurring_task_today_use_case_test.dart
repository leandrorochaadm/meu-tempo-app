import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/recurring_task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/weekday_enum.dart';
import 'package:meu_tempo/features/task/domain/repositories/recurring_task_repository.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart';
import 'package:meu_tempo/features/task/domain/task_failures.dart';
import 'package:meu_tempo/features/task/domain/usecases/add_recurring_task_today_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/create_task_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepo extends Mock implements TaskRepository {}

class _MockRecurringRepo extends Mock implements RecurringTaskRepository {}

class _FakeTask extends Fake implements TaskEntity {}

void main() {
  late _MockTaskRepo taskRepo;
  late _MockRecurringRepo recurringRepo;
  late AddRecurringTaskTodayUseCase useCase;
  final monday = DateTime(2026, 10, 12);
  final tuesday = DateTime(2026, 10, 13);

  RecurringTaskEntity template({Set<WeekdayEnum> weekdays = const {}}) =>
      RecurringTaskEntity(
        id: 'r1',
        title: 'Academia',
        listId: 'l1',
        estimatedMinutes: 60,
        importance: ImportanceEnum.high,
        weekdays: weekdays,
        createdAt: DateTime(2026, 10),
      );

  TaskEntity instance({bool isDone = false}) => TaskEntity(
    id: 't0',
    title: 'Academia',
    listId: 'l1',
    createdAt: DateTime(2026, 10, 5),
    dueDate: DateTime(2026, 10, 5),
    isDone: isDone,
    recurringTaskId: 'r1',
  );

  void stubTasks(List<TaskEntity> tasks) =>
      when(() => taskRepo.getTasks()).thenAnswer((_) async => Right(tasks));

  setUpAll(() {
    registerFallbackValue(_FakeTask());
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    taskRepo = _MockTaskRepo();
    recurringRepo = _MockRecurringRepo();
    useCase = AddRecurringTaskTodayUseCase(
      taskRepo,
      recurringRepo,
      CreateTaskUseCase(taskRepo),
    );
    when(
      () => taskRepo.create(any()),
    ).thenAnswer((i) async => Right(i.positionalArguments.first as TaskEntity));
    when(
      () => recurringRepo.claimGeneration(any(), any()),
    ).thenAnswer((_) async => const Right(true));
    stubTasks(const []);
  });

  test('should create when unscheduled even with pending', () async {
    stubTasks([instance()]);
    final r = await useCase(
      AddRecurringTaskTodayParams(template: template(), today: monday),
    );
    expect(r.isRight(), isTrue);
    verify(() => taskRepo.create(any())).called(1);
    verifyNever(() => taskRepo.getTasks());
    verifyNever(() => recurringRepo.claimGeneration(any(), any()));
  });

  test(
    'should return PendingRecurringInstanceFailure when scheduled and pending',
    () async {
      stubTasks([instance()]);
      final r = await useCase(
        AddRecurringTaskTodayParams(
          template: template(weekdays: {WeekdayEnum.monday}),
          today: monday,
        ),
      );
      expect(
        r,
        const Left<Failure, TaskEntity>(PendingRecurringInstanceFailure()),
      );
      verifyNever(() => taskRepo.create(any()));
      verifyNever(() => recurringRepo.claimGeneration(any(), any()));
    },
  );

  test('should create when confirmed', () async {
    stubTasks([instance()]);
    final r = await useCase(
      AddRecurringTaskTodayParams(
        template: template(weekdays: {WeekdayEnum.monday}),
        today: monday,
        confirmed: true,
      ),
    );
    expect(r.isRight(), isTrue);
    verifyNever(() => taskRepo.getTasks());
  });

  test('should create when scheduled and only done instances exist', () async {
    stubTasks([instance(isDone: true)]);
    final r = await useCase(
      AddRecurringTaskTodayParams(
        template: template(weekdays: {WeekdayEnum.monday}),
        today: monday,
      ),
    );
    expect(r.isRight(), isTrue);
  });

  test('should copy template fields to the task', () async {
    await useCase(
      AddRecurringTaskTodayParams(template: template(), today: monday),
    );
    final task =
        verify(() => taskRepo.create(captureAny())).captured.single
            as TaskEntity;
    expect(task.title, 'Academia');
    expect(task.listId, 'l1');
    expect(task.estimatedMinutes, 60);
    expect(task.importance, ImportanceEnum.high);
    expect(task.dueDate, monday);
    expect(task.createdAt, monday);
    expect(task.recurringTaskId, 'r1');
  });

  test('should claim generation when due today', () async {
    await useCase(
      AddRecurringTaskTodayParams(
        template: template(weekdays: {WeekdayEnum.monday}),
        today: monday,
      ),
    );
    verify(() => recurringRepo.claimGeneration('r1', monday)).called(1);
  });

  test('should not claim generation when not due today', () async {
    await useCase(
      AddRecurringTaskTodayParams(
        template: template(weekdays: {WeekdayEnum.monday}),
        today: tuesday,
      ),
    );
    verifyNever(() => recurringRepo.claimGeneration(any(), any()));
  });

  test('should ignore claimGeneration failure', () async {
    when(
      () => recurringRepo.claimGeneration(any(), any()),
    ).thenAnswer((_) async => const Left(ServerFailure()));
    final r = await useCase(
      AddRecurringTaskTodayParams(
        template: template(weekdays: {WeekdayEnum.monday}),
        today: monday,
      ),
    );
    expect(r.isRight(), isTrue);
  });

  test('should return getTasks failure', () async {
    when(
      () => taskRepo.getTasks(),
    ).thenAnswer((_) async => const Left(ServerFailure()));
    final r = await useCase(
      AddRecurringTaskTodayParams(
        template: template(weekdays: {WeekdayEnum.monday}),
        today: monday,
      ),
    );
    expect(r, const Left<Failure, TaskEntity>(ServerFailure()));
    verifyNever(() => taskRepo.create(any()));
  });

  test('should return create failure without claiming', () async {
    when(
      () => taskRepo.create(any()),
    ).thenAnswer((_) async => const Left(ServerFailure()));
    final r = await useCase(
      AddRecurringTaskTodayParams(
        template: template(weekdays: {WeekdayEnum.monday}),
        today: monday,
      ),
    );
    expect(r, const Left<Failure, TaskEntity>(ServerFailure()));
    verifyNever(() => recurringRepo.claimGeneration(any(), any()));
  });
}
