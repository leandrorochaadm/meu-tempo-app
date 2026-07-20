import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/list/domain/usecases/ensure_inbox_exists_use_case.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/usecases/add_subtask_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/build_task_tree_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/create_task_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/watch_tasks_use_case.dart';
import 'package:meu_tempo/features/task/presentation/bloc/task_list_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchTasks extends Mock implements WatchTasksUseCase {}

class _MockCreateTask extends Mock implements CreateTaskUseCase {}

class _MockEnsureInbox extends Mock implements EnsureInboxExistsUseCase {}

class _MockAddSubtask extends Mock implements AddSubtaskUseCase {}

class _FakeNoParams extends Fake implements NoParams {}

class _FakeCreateParams extends Fake implements CreateTaskParams {}

class _FakeSubtaskParams extends Fake implements AddSubtaskParams {}

void main() {
  late _MockWatchTasks watchTasks;
  late _MockCreateTask createTask;
  late _MockEnsureInbox ensureInbox;
  late _MockAddSubtask addSubtask;
  const buildTree = BuildTaskTreeUseCase();

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
    registerFallbackValue(_FakeSubtaskParams());
  });

  setUp(() {
    watchTasks = _MockWatchTasks();
    createTask = _MockCreateTask();
    ensureInbox = _MockEnsureInbox();
    addSubtask = _MockAddSubtask();
    when(() => ensureInbox(any())).thenAnswer((_) async => const Right(inbox));
  });

  TaskListBloc build() =>
      TaskListBloc(watchTasks, createTask, ensureInbox, addSubtask, buildTree);

  blocTest<TaskListBloc, TaskListState>(
    'started com tarefas emite [Loading, Loaded] com a árvore montada',
    build: () {
      when(() => watchTasks(any()))
          .thenAnswer((_) => Stream.value(Right([task])));
      return build();
    },
    act: (bloc) => bloc.add(const TaskListStarted()),
    expect: () => [
      const TaskListLoading(),
      isA<TaskListLoaded>().having(
        (s) => s.roots.single.task,
        'raiz',
        task,
      ),
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
    expect: () => [const TaskListLoading(), const TaskListEmpty()],
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
    expect: () => [const TaskListLoading(), isA<TaskListError>()],
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
      final captured = verify(() => createTask(captureAny())).captured.single
          as CreateTaskParams;
      expect(captured.title, 'Estudar');
      expect(captured.listId, 'inbox');
    },
  );

  blocTest<TaskListBloc, TaskListState>(
    'SubtaskRequested delega ao AddSubtaskUseCase com o nível do pai',
    build: () {
      when(() => watchTasks(any()))
          .thenAnswer((_) => Stream.value(const Right(<TaskEntity>[])));
      when(() => addSubtask(any())).thenAnswer((_) async => Right(task));
      return build();
    },
    act: (bloc) async {
      bloc.add(const TaskListStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const SubtaskRequested(
        parentId: 'p1',
        parentLevel: 0,
        listId: 'inbox',
        title: 'Fazer telas',
      ));
    },
    verify: (_) {
      final captured = verify(() => addSubtask(captureAny())).captured.single
          as AddSubtaskParams;
      expect(captured.parentId, 'p1');
      expect(captured.parentLevel, 0);
      expect(captured.title, 'Fazer telas');
    },
  );
}
