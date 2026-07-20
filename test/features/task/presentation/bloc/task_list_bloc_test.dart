import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/list/domain/usecases/ensure_inbox_exists_use_case.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/usecases/create_task_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/watch_tasks_use_case.dart';
import 'package:meu_tempo/features/task/presentation/bloc/task_list_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchTasks extends Mock implements WatchTasksUseCase {}

class _MockCreateTask extends Mock implements CreateTaskUseCase {}

class _MockEnsureInbox extends Mock implements EnsureInboxExistsUseCase {}

class _FakeNoParams extends Fake implements NoParams {}

class _FakeCreateParams extends Fake implements CreateTaskParams {}

void main() {
  late _MockWatchTasks watchTasks;
  late _MockCreateTask createTask;
  late _MockEnsureInbox ensureInbox;

  const inbox = TaskListEntity(id: 'inbox', name: 'Entrada', isDefault: true);
  final task = TaskEntity(
    id: 't1',
    title: 'Estudar',
    listId: 'inbox',
    createdAt: DateTime(2026, 7, 20),
  );

  setUpAll(() {
    registerFallbackValue(_FakeNoParams());
    registerFallbackValue(_FakeCreateParams());
  });

  setUp(() {
    watchTasks = _MockWatchTasks();
    createTask = _MockCreateTask();
    ensureInbox = _MockEnsureInbox();
    when(() => ensureInbox(any())).thenAnswer((_) async => const Right(inbox));
  });

  TaskListBloc build() => TaskListBloc(watchTasks, createTask, ensureInbox);

  blocTest<TaskListBloc, TaskListState>(
    'started com tarefas emite [Loading, Loaded]',
    build: () {
      when(() => watchTasks(any()))
          .thenAnswer((_) => Stream.value(Right([task])));
      return build();
    },
    act: (bloc) => bloc.add(const TaskListStarted()),
    expect: () => [
      const TaskListLoading(),
      TaskListLoaded([task]),
    ],
  );

  blocTest<TaskListBloc, TaskListState>(
    'started sem tarefas emite [Loading, Empty]',
    build: () {
      when(() => watchTasks(any())).thenAnswer(
        (_) => Stream.value(const Right(<TaskEntity>[])),
      );
      return build();
    },
    act: (bloc) => bloc.add(const TaskListStarted()),
    expect: () => [
      const TaskListLoading(),
      const TaskListEmpty(),
    ],
  );

  blocTest<TaskListBloc, TaskListState>(
    'started emite Error quando o stream falha',
    build: () {
      when(() => watchTasks(any())).thenAnswer(
        (_) => Stream.value(const Left(ServerFailure())),
      );
      return build();
    },
    act: (bloc) => bloc.add(const TaskListStarted()),
    expect: () => [
      const TaskListLoading(),
      isA<TaskListError>(),
    ],
  );

  blocTest<TaskListBloc, TaskListState>(
    'TaskCreated chama o UseCase com a lista Entrada',
    build: () {
      when(() => watchTasks(any()))
          .thenAnswer((_) => Stream.value(const Right(<TaskEntity>[])));
      when(() => createTask(any())).thenAnswer((_) async => Right(task));
      return build();
    },
    act: (bloc) async {
      bloc.add(const TaskListStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const TaskCreated('Estudar'));
    },
    verify: (_) {
      final captured =
          verify(() => createTask(captureAny())).captured.single
              as CreateTaskParams;
      expect(captured.title, 'Estudar');
      expect(captured.listId, 'inbox');
    },
  );

  blocTest<TaskListBloc, TaskListState>(
    'TaskCreated com falha emite TaskListError',
    build: () {
      when(() => watchTasks(any()))
          .thenAnswer((_) => Stream.value(const Right(<TaskEntity>[])));
      when(() => createTask(any()))
          .thenAnswer((_) async => const Left(ServerFailure()));
      return build();
    },
    act: (bloc) async {
      bloc.add(const TaskListStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const TaskCreated('X'));
    },
    expect: () => [
      const TaskListLoading(),
      const TaskListEmpty(),
      isA<TaskListError>(),
    ],
  );
}
