import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/list/domain/repositories/task_list_repository.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart';
import 'package:meu_tempo/features/task/domain/task_failures.dart';
import 'package:meu_tempo/features/task/domain/usecases/build_task_tree_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/get_prioritized_leaves_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/get_task_edit_context_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/get_task_edit_target_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepo extends Mock implements TaskRepository {}

class _MockListRepo extends Mock implements TaskListRepository {}

void main() {
  late _MockTaskRepo taskRepo;
  late _MockListRepo listRepo;
  late GetTaskEditTargetUseCase useCase;

  final created = DateTime(2026, 10, 7);
  final parent = TaskEntity(
    id: 'mae',
    title: 'Projeto',
    listId: 'work',
    createdAt: created,
    hasChildren: true,
  );
  final child = TaskEntity(
    id: 't1',
    title: 'Tela de login',
    listId: 'work',
    createdAt: created,
    parentId: 'mae',
  );
  final done = TaskEntity(
    id: 'done',
    title: 'Feita',
    listId: 'work',
    createdAt: created,
    isDone: true,
  );
  const work = TaskListEntity(id: 'work', name: 'Trabalho');

  setUp(() {
    taskRepo = _MockTaskRepo();
    listRepo = _MockListRepo();
    useCase = GetTaskEditTargetUseCase(
      taskRepo,
      listRepo,
      const GetTaskEditContextUseCase(
        BuildTaskTreeUseCase(GetPrioritizedLeavesUseCase()),
      ),
    );
    when(() => taskRepo.getTasks())
        .thenAnswer((_) async => Right([parent, child, done]));
    when(() => listRepo.getLists()).thenAnswer((_) async => const Right([work]));
  });

  test('finds the task by id with context and lists', () async {
    final result =
        await useCase(const GetTaskEditTargetParams(taskId: 't1'));

    final target = result.getRight().toNullable()!;
    expect(target.editContext.task.id, 't1');
    expect(target.editContext.currentParentLabel, isNotEmpty);
    expect(target.lists, [work]);
  });

  test('done task also opens', () async {
    final result =
        await useCase(const GetTaskEditTargetParams(taskId: 'done'));

    expect(result.isRight(), isTrue);
  });

  test('deleted task returns TaskNotFoundFailure', () async {
    final result = await useCase(const GetTaskEditTargetParams(taskId: 'x'));

    expect(result, const Left(TaskNotFoundFailure()));
  });

  test('failure on tasks is returned and the lists are not read', () async {
    when(() => taskRepo.getTasks())
        .thenAnswer((_) async => const Left(NetworkFailure()));

    final result =
        await useCase(const GetTaskEditTargetParams(taskId: 't1'));

    expect(result, const Left(NetworkFailure()));
    verifyNever(() => listRepo.getLists());
  });

  test('failure on lists is returned', () async {
    when(() => listRepo.getLists())
        .thenAnswer((_) async => const Left(ServerFailure()));

    final result =
        await useCase(const GetTaskEditTargetParams(taskId: 't1'));

    expect(result, const Left(ServerFailure()));
  });

  test('Params with the same id are equal', () {
    expect(
      const GetTaskEditTargetParams(taskId: 't1'),
      const GetTaskEditTargetParams(taskId: 't1'),
    );
  });
}
