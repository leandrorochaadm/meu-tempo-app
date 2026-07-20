import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/list/domain/repositories/task_list_repository.dart';
import 'package:meu_tempo/features/list/domain/usecases/watch_lists_use_case.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart';
import 'package:meu_tempo/features/task/domain/usecases/watch_tasks_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepository extends Mock implements TaskRepository {}

class _MockTaskListRepository extends Mock implements TaskListRepository {}

void main() {
  test('WatchTasksUseCase repassa o stream do repositório', () async {
    final repo = _MockTaskRepository();
    final task = TaskEntity(
      id: 't1',
      title: 'X',
      listId: 'inbox',
      createdAt: DateTime(2026, 7, 20),
    );
    when(() => repo.watchTasks())
        .thenAnswer((_) => Stream.value(Right([task])));

    final stream = WatchTasksUseCase(repo)(const NoParams());

    await expectLater(
      stream,
      emits(predicate<Either<Failure, List<TaskEntity>>>(
        (e) => e.getRight().toNullable()?.single == task,
      )),
    );
  });

  test('WatchListsUseCase repassa o stream do repositório', () async {
    final repo = _MockTaskListRepository();
    const list = TaskListEntity(id: 'l1', name: 'Entrada', isDefault: true);
    when(() => repo.watchLists())
        .thenAnswer((_) => Stream.value(const Right([list])));

    final stream = WatchListsUseCase(repo)(const NoParams());

    await expectLater(
      stream,
      emits(predicate<Either<Failure, List<TaskListEntity>>>(
        (e) => e.getRight().toNullable()?.single == list,
      )),
    );
  });
}
