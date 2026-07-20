import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/list/domain/usecases/ensure_inbox_exists_use_case.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/active_timer_entity.dart';
import 'package:meu_tempo/features/task/domain/task_failures.dart';
import 'package:meu_tempo/features/task/domain/usecases/add_subtask_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/build_task_tree_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/complete_task_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/create_task_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/delete_task_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/get_prioritized_leaves_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/register_manual_time_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/start_timer_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/stop_timer_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/watch_active_timer_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/watch_tasks_use_case.dart';
import 'package:meu_tempo/features/task/presentation/bloc/task_list_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchTasks extends Mock implements WatchTasksUseCase {}

class _MockCreateTask extends Mock implements CreateTaskUseCase {}

class _MockEnsureInbox extends Mock implements EnsureInboxExistsUseCase {}

class _MockAddSubtask extends Mock implements AddSubtaskUseCase {}

class _MockWatchActiveTimer extends Mock implements WatchActiveTimerUseCase {}

class _MockStartTimer extends Mock implements StartTimerUseCase {}

class _MockStopTimer extends Mock implements StopTimerUseCase {}

class _MockManualTime extends Mock implements RegisterManualTimeUseCase {}

class _MockComplete extends Mock implements CompleteTaskUseCase {}

class _MockDelete extends Mock implements DeleteTaskUseCase {}

class _FakeNoParams extends Fake implements NoParams {}

class _FakeCreateParams extends Fake implements CreateTaskParams {}

class _FakeSubtaskParams extends Fake implements AddSubtaskParams {}

class _FakeStartParams extends Fake implements StartTimerParams {}

class _FakeStopParams extends Fake implements StopTimerParams {}

class _FakeManualParams extends Fake implements RegisterManualTimeParams {}

class _FakeCompleteParams extends Fake implements CompleteTaskParams {}

class _FakeDeleteParams extends Fake implements DeleteTaskParams {}

void main() {
  late _MockWatchTasks watchTasks;
  late _MockCreateTask createTask;
  late _MockEnsureInbox ensureInbox;
  late _MockAddSubtask addSubtask;
  late _MockWatchActiveTimer watchActiveTimer;
  late _MockStartTimer startTimer;
  late _MockStopTimer stopTimer;
  late _MockManualTime manualTime;
  late _MockComplete completeTask;
  late _MockDelete deleteTask;
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
    registerFallbackValue(_FakeStartParams());
    registerFallbackValue(_FakeStopParams());
    registerFallbackValue(_FakeManualParams());
    registerFallbackValue(_FakeCompleteParams());
    registerFallbackValue(_FakeDeleteParams());
  });

  setUp(() {
    watchTasks = _MockWatchTasks();
    createTask = _MockCreateTask();
    ensureInbox = _MockEnsureInbox();
    addSubtask = _MockAddSubtask();
    watchActiveTimer = _MockWatchActiveTimer();
    startTimer = _MockStartTimer();
    stopTimer = _MockStopTimer();
    manualTime = _MockManualTime();
    completeTask = _MockComplete();
    deleteTask = _MockDelete();
    when(() => ensureInbox(any())).thenAnswer((_) async => const Right(inbox));
    when(() => watchActiveTimer(any())).thenAnswer(
      (_) => const Stream<Either<Failure, ActiveTimerEntity?>>.empty(),
    );
  });

  const getPrioritized = GetPrioritizedLeavesUseCase();

  TaskListBloc build() => TaskListBloc(
        watchTasks,
        createTask,
        ensureInbox,
        addSubtask,
        buildTree,
        getPrioritized,
        watchActiveTimer,
        startTimer,
        stopTimer,
        manualTime,
        completeTask,
        deleteTask,
      );

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

  blocTest<TaskListBloc, TaskListState>(
    'TimerStartRequested delega ao StartTimerUseCase',
    build: () {
      when(() => watchTasks(any()))
          .thenAnswer((_) => Stream.value(const Right(<TaskEntity>[])));
      when(() => startTimer(any())).thenAnswer((_) async => const Right(unit));
      return build();
    },
    act: (bloc) async {
      bloc.add(const TaskListStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const TimerStartRequested(taskId: 't1', isLeaf: true));
    },
    verify: (_) {
      final p = verify(() => startTimer(captureAny())).captured.single
          as StartTimerParams;
      expect(p.targetId, 't1');
      expect(p.targetIsLeaf, isTrue);
    },
  );

  blocTest<TaskListBloc, TaskListState>(
    'ManualTimeRequested com folha inválida emite erro',
    build: () {
      when(() => watchTasks(any()))
          .thenAnswer((_) => Stream.value(const Right(<TaskEntity>[])));
      when(() => manualTime(any()))
          .thenAnswer((_) async => const Left(TimerOnNonLeafFailure()));
      return build();
    },
    act: (bloc) async {
      bloc.add(const TaskListStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ManualTimeRequested(
        taskId: 'm1',
        isLeaf: false,
        minutes: 30,
      ));
    },
    expect: () => [
      const TaskListLoading(),
      const TaskListEmpty(),
      isA<TaskListError>(),
    ],
  );

  blocTest<TaskListBloc, TaskListState>(
    'CompleteToggled delega ao CompleteTaskUseCase',
    build: () {
      when(() => watchTasks(any()))
          .thenAnswer((_) => Stream.value(const Right(<TaskEntity>[])));
      when(() => completeTask(any())).thenAnswer((_) async => const Right(unit));
      return build();
    },
    act: (bloc) async {
      bloc.add(const TaskListStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const CompleteToggled(taskId: 't1', done: true));
    },
    verify: (_) {
      final p = verify(() => completeTask(captureAny())).captured.single
          as CompleteTaskParams;
      expect(p.taskId, 't1');
      expect(p.done, isTrue);
    },
  );

  blocTest<TaskListBloc, TaskListState>(
    'DeleteRequested delega ao DeleteTaskUseCase',
    build: () {
      when(() => watchTasks(any()))
          .thenAnswer((_) => Stream.value(const Right(<TaskEntity>[])));
      when(() => deleteTask(any())).thenAnswer((_) async => const Right(unit));
      return build();
    },
    act: (bloc) async {
      bloc.add(const TaskListStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const DeleteRequested('t1'));
    },
    verify: (_) {
      final p = verify(() => deleteTask(captureAny())).captured.single
          as DeleteTaskParams;
      expect(p.taskId, 't1');
    },
  );
}
