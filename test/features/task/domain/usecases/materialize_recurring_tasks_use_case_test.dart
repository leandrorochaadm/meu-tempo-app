import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/recurring_task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/weekday_enum.dart';
import 'package:meu_tempo/features/task/domain/repositories/recurring_task_repository.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart';
import 'package:meu_tempo/features/task/domain/usecases/add_recurring_task_today_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/create_task_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/materialize_recurring_tasks_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepo extends Mock implements TaskRepository {}

class _MockRecurringRepo extends Mock implements RecurringTaskRepository {}

class _FakeTask extends Fake implements TaskEntity {}

void main() {
  late _MockTaskRepo taskRepo;
  late _MockRecurringRepo recurringRepo;
  late MaterializeRecurringTasksUseCase useCase;
  final monday = DateTime(2026, 10, 12);
  final params = MaterializeRecurringTasksParams(today: monday);

  RecurringTaskEntity template(
    String id, {
    Set<WeekdayEnum> weekdays = const {WeekdayEnum.monday},
    DateTime? lastGeneratedOn,
  }) => RecurringTaskEntity(
    id: id,
    title: 'Modelo $id',
    listId: 'l1',
    estimatedMinutes: 30,
    importance: ImportanceEnum.high,
    weekdays: weekdays,
    createdAt: DateTime(2026, 10),
    lastGeneratedOn: lastGeneratedOn,
  );

  void stubTemplates(List<RecurringTaskEntity> list) =>
      when(() => recurringRepo.getAll()).thenAnswer((_) async => Right(list));

  setUpAll(() {
    registerFallbackValue(_FakeTask());
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    taskRepo = _MockTaskRepo();
    recurringRepo = _MockRecurringRepo();
    final createTask = CreateTaskUseCase(taskRepo);
    useCase = MaterializeRecurringTasksUseCase(
      recurringRepo,
      taskRepo,
      AddRecurringTaskTodayUseCase(taskRepo, recurringRepo, createTask),
    );
    when(() => taskRepo.getTasks()).thenAnswer((_) async => const Right([]));
    when(
      () => taskRepo.create(any()),
    ).thenAnswer((i) async => Right(i.positionalArguments.first as TaskEntity));
    when(
      () => recurringRepo.claimGeneration(any(), any()),
    ).thenAnswer((_) async => const Right(true));
  });

  test('should spawn due templates', () async {
    stubTemplates([
      template('r1'),
      template('r2', weekdays: {WeekdayEnum.monday, WeekdayEnum.friday}),
    ]);
    final r = await useCase(params);
    expect(r, const Right<Failure, int>(2));
    final created = verify(
      () => taskRepo.create(captureAny()),
    ).captured.cast<TaskEntity>();
    expect(created.map((t) => t.recurringTaskId), ['r1', 'r2']);
  });

  test('should not spawn on other weekdays', () async {
    stubTemplates([
      template('r1', weekdays: {WeekdayEnum.tuesday}),
    ]);
    expect(await useCase(params), const Right<Failure, int>(0));
    verifyNever(() => recurringRepo.claimGeneration(any(), any()));
    verifyNever(() => taskRepo.create(any()));
  });

  test('should skip already generated today', () async {
    stubTemplates([template('r1', lastGeneratedOn: monday)]);
    expect(await useCase(params), const Right<Failure, int>(0));
    verifyNever(() => recurringRepo.claimGeneration(any(), any()));
  });

  test('should skip pending', () async {
    stubTemplates([template('r1')]);
    when(() => taskRepo.getTasks()).thenAnswer(
      (_) async => Right([
        TaskEntity(
          id: 't0',
          title: 'x',
          listId: 'l1',
          createdAt: DateTime(2026, 10, 5),
          dueDate: DateTime(2026, 10, 5),
          recurringTaskId: 'r1',
        ),
      ]),
    );
    expect(await useCase(params), const Right<Failure, int>(0));
    verifyNever(() => recurringRepo.claimGeneration(any(), any()));
  });

  test('should skip unscheduled', () async {
    stubTemplates([template('r1', weekdays: const {})]);
    expect(await useCase(params), const Right<Failure, int>(0));
  });

  test('should skip when claimGeneration returns false', () async {
    stubTemplates([template('r1')]);
    when(
      () => recurringRepo.claimGeneration(any(), any()),
    ).thenAnswer((_) async => const Right(false));
    expect(await useCase(params), const Right<Failure, int>(0));
    verifyNever(() => taskRepo.create(any()));
  });

  test('should claim before creating', () async {
    stubTemplates([template('r1')]);
    await useCase(params);
    verifyInOrder([
      () => recurringRepo.claimGeneration('r1', monday),
      () => taskRepo.create(any()),
    ]);
  });

  test('should return failure when getAll fails', () async {
    when(
      () => recurringRepo.getAll(),
    ).thenAnswer((_) async => const Left(ServerFailure()));
    expect(await useCase(params), const Left<Failure, int>(ServerFailure()));
  });

  test('should return failure when getTasks fails', () async {
    stubTemplates([template('r1')]);
    when(
      () => taskRepo.getTasks(),
    ).thenAnswer((_) async => const Left(ServerFailure()));
    expect(await useCase(params), const Left<Failure, int>(ServerFailure()));
    verifyNever(() => taskRepo.create(any()));
  });

  test('should stop on claimGeneration failure', () async {
    stubTemplates([template('r1')]);
    when(
      () => recurringRepo.claimGeneration(any(), any()),
    ).thenAnswer((_) async => const Left(ServerFailure()));
    expect(await useCase(params), const Left<Failure, int>(ServerFailure()));
    verifyNever(() => taskRepo.create(any()));
  });

  test('should read templates and tasks once', () async {
    stubTemplates([template('r1'), template('r2')]);
    await useCase(params);
    verify(() => recurringRepo.getAll()).called(1);
    verify(() => taskRepo.getTasks()).called(1);
  });
}
