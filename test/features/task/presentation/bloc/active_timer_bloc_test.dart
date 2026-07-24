import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/list/domain/usecases/watch_lists_use_case.dart';
import 'package:meu_tempo/features/task/domain/entities/active_timer_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:meu_tempo/features/task/domain/task_failures.dart';
import 'package:meu_tempo/features/task/domain/usecases/build_task_tree_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/complete_task_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/edit_task_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/get_task_edit_context_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/move_task_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/stop_timer_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/watch_active_timer_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/watch_tasks_use_case.dart';
import 'package:meu_tempo/features/task/presentation/bloc/active_timer_bloc.dart';
import 'package:meu_tempo/features/task/presentation/pages/edit_task_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchActiveTimer extends Mock implements WatchActiveTimerUseCase {}

class _MockWatchTasks extends Mock implements WatchTasksUseCase {}

class _MockWatchLists extends Mock implements WatchListsUseCase {}

class _MockStopTimer extends Mock implements StopTimerUseCase {}

class _MockEditTask extends Mock implements EditTaskUseCase {}

class _MockMoveTask extends Mock implements MoveTaskUseCase {}

class _MockCompleteTask extends Mock implements CompleteTaskUseCase {}

void main() {
  late _MockWatchActiveTimer watchActiveTimer;
  late _MockWatchTasks watchTasks;
  late _MockWatchLists watchLists;
  late _MockStopTimer stopTimer;
  late _MockEditTask editTask;
  late _MockMoveTask moveTask;
  late _MockCompleteTask completeTask;

  const getEditContext = GetTaskEditContextUseCase(BuildTaskTreeUseCase());
  final today = DateTime(2026, 7, 22);

  final leaf = TaskEntity(
    id: 't1',
    title: 'Fazer telas',
    listId: 'inbox',
    createdAt: today,
  );
  final activeOnTask = ActiveTimerEntity(
    targetId: 't1',
    targetType: TimerTargetTypeEnum.task,
    listId: 'inbox',
    startedAt: DateTime(2026, 7, 22, 10),
  );
  final activeOnAppointment = ActiveTimerEntity(
    targetId: 'a1',
    targetType: TimerTargetTypeEnum.appointment,
    listId: 'inbox',
    startedAt: DateTime(2026, 7, 22, 10),
  );

  EditTaskResult editResult({
    bool parentChanged = false,
    bool doneChanged = false,
    bool isDone = false,
  }) =>
      EditTaskResult(
        title: 'Novo título',
        estimatedMinutes: 30,
        dueDate: null,
        importance: null,
        listId: 'inbox',
        newParentId: parentChanged ? 'mae' : null,
        parentChanged: parentChanged,
        isDone: isDone,
        doneChanged: doneChanged,
      );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const WatchTasksParams());
    registerFallbackValue(StopTimerParams(now: today));
    registerFallbackValue(const CompleteTaskParams(taskId: 't1', done: true));
    registerFallbackValue(const EditTaskParams(taskId: 't1', title: 'x'));
    registerFallbackValue(const MoveTaskParams(taskId: 't1'));
  });

  setUp(() {
    watchActiveTimer = _MockWatchActiveTimer();
    watchTasks = _MockWatchTasks();
    watchLists = _MockWatchLists();
    stopTimer = _MockStopTimer();
    editTask = _MockEditTask();
    moveTask = _MockMoveTask();
    completeTask = _MockCompleteTask();

    // Padrão: nada rodando, sem tarefas/listas.
    when(() => watchActiveTimer(any())).thenAnswer(
      (_) => Stream.value(const Right<Failure, ActiveTimerEntity?>(null)),
    );
    when(() => watchTasks(any())).thenAnswer(
      (_) => Stream.value(Right<Failure, List<TaskEntity>>([leaf])),
    );
    when(() => watchLists(any())).thenAnswer(
      (_) => Stream.value(
        const Right<Failure, List<TaskListEntity>>([]),
      ),
    );
    when(() => stopTimer(any())).thenAnswer((_) async => const Right(unit));
    when(() => completeTask(any())).thenAnswer((_) async => const Right(unit));
    when(() => editTask(any())).thenAnswer((_) async => const Right(unit));
    when(() => moveTask(any())).thenAnswer((_) async => const Right(unit));
  });

  ActiveTimerBloc build() => ActiveTimerBloc(
        watchActiveTimer,
        watchTasks,
        watchLists,
        stopTimer,
        getEditContext,
        editTask,
        moveTask,
        completeTask,
      );

  blocTest<ActiveTimerBloc, ActiveTimerState>(
    'exibe a barra quando o cronômetro roda numa folha resolvida',
    build: () {
      when(() => watchActiveTimer(any())).thenAnswer(
        (_) => Stream.value(Right<Failure, ActiveTimerEntity?>(activeOnTask)),
      );
      return build();
    },
    act: (bloc) => bloc.add(const ActiveTimerStarted()),
    wait: const Duration(milliseconds: 50),
    verify: (bloc) {
      expect(bloc.state, isA<ActiveTimerRunning>());
      expect((bloc.state as ActiveTimerRunning).title, 'Fazer telas');
    },
  );

  blocTest<ActiveTimerBloc, ActiveTimerState>(
    'não exibe a barra quando o cronômetro roda num compromisso',
    build: () {
      when(() => watchActiveTimer(any())).thenAnswer(
        (_) => Stream.value(
          Right<Failure, ActiveTimerEntity?>(activeOnAppointment),
        ),
      );
      return build();
    },
    act: (bloc) => bloc.add(const ActiveTimerStarted()),
    wait: const Duration(milliseconds: 50),
    verify: (bloc) => expect(bloc.state, isA<ActiveTimerHidden>()),
  );

  blocTest<ActiveTimerBloc, ActiveTimerState>(
    'parar chama o StopTimerUseCase',
    build: build,
    act: (bloc) => bloc.add(const ActiveTimerStopRequested()),
    verify: (_) => verify(() => stopTimer(any())).called(1),
  );

  blocTest<ActiveTimerBloc, ActiveTimerState>(
    'falha ao parar emite ActiveTimerActionFailed com mensagem',
    build: () {
      when(() => stopTimer(any()))
          .thenAnswer((_) async => const Left(NetworkFailure()));
      return build();
    },
    act: (bloc) => bloc.add(const ActiveTimerStopRequested()),
    expect: () => [
      isA<ActiveTimerActionFailed>().having(
        (s) => s.message,
        'mensagem',
        'Sem conexão. Verifique a internet.',
      ),
    ],
  );

  blocTest<ActiveTimerBloc, ActiveTimerState>(
    'concluir para o cronômetro e conclui a folha',
    build: build,
    act: (bloc) => bloc.add(const ActiveTimerCompleteRequested('t1')),
    verify: (_) {
      verify(() => stopTimer(any())).called(1);
      verify(() => completeTask(
            any(that: isA<CompleteTaskParams>()),
          )).called(1);
    },
  );

  blocTest<ActiveTimerBloc, ActiveTimerState>(
    'falha ao concluir (após parar) emite ActiveTimerActionFailed',
    build: () {
      when(() => completeTask(any()))
          .thenAnswer((_) async => const Left(NetworkFailure()));
      return build();
    },
    act: (bloc) => bloc.add(const ActiveTimerCompleteRequested('t1')),
    expect: () => [isA<ActiveTimerActionFailed>()],
    verify: (_) => verify(() => stopTimer(any())).called(1),
  );

  blocTest<ActiveTimerBloc, ActiveTimerState>(
    'editar sem mudança de mãe/conclusão só chama EditTaskUseCase',
    build: build,
    act: (bloc) =>
        bloc.add(ActiveTimerEditSubmitted('t1', editResult())),
    verify: (_) {
      verify(() => editTask(any())).called(1);
      verifyNever(() => moveTask(any()));
      verifyNever(() => completeTask(any()));
    },
  );

  blocTest<ActiveTimerBloc, ActiveTimerState>(
    'editar com parentChanged e doneChanged dispara move e complete',
    build: build,
    act: (bloc) => bloc.add(ActiveTimerEditSubmitted(
      't1',
      editResult(parentChanged: true, doneChanged: true, isDone: true),
    )),
    verify: (_) {
      verify(() => editTask(any())).called(1);
      verify(() => moveTask(any())).called(1);
      verify(() => completeTask(any())).called(1);
    },
  );

  blocTest<ActiveTimerBloc, ActiveTimerState>(
    'falha ao editar interrompe a sequência (não move nem conclui) e avisa',
    build: () {
      when(() => editTask(any()))
          .thenAnswer((_) async => const Left(TaskNotFoundFailure()));
      return build();
    },
    act: (bloc) => bloc.add(ActiveTimerEditSubmitted(
      't1',
      editResult(parentChanged: true, doneChanged: true, isDone: true),
    )),
    expect: () => [
      isA<ActiveTimerActionFailed>().having(
        (s) => s.message,
        'mensagem',
        'Tarefa não encontrada.',
      ),
    ],
    verify: (_) {
      verifyNever(() => moveTask(any()));
      verifyNever(() => completeTask(any()));
    },
  );

  blocTest<ActiveTimerBloc, ActiveTimerState>(
    'falha ao mover (parentChanged) emite mensagem específica',
    build: () {
      when(() => moveTask(any()))
          .thenAnswer((_) async => const Left(InvalidMoveFailure()));
      return build();
    },
    act: (bloc) => bloc.add(ActiveTimerEditSubmitted(
      't1',
      editResult(parentChanged: true),
    )),
    expect: () => [
      isA<ActiveTimerActionFailed>().having(
        (s) => s.message,
        'mensagem',
        'Não dá para mover a tarefa para lá.',
      ),
    ],
  );

  blocTest<ActiveTimerBloc, ActiveTimerState>(
    'alvo não encontrado na lista de tarefas mantém a barra escondida',
    build: () {
      when(() => watchActiveTimer(any())).thenAnswer(
        (_) => Stream.value(Right<Failure, ActiveTimerEntity?>(activeOnTask)),
      );
      // Lista sem a folha 't1'.
      when(() => watchTasks(any())).thenAnswer(
        (_) => Stream.value(const Right<Failure, List<TaskEntity>>([])),
      );
      return build();
    },
    act: (bloc) => bloc.add(const ActiveTimerStarted()),
    wait: const Duration(milliseconds: 50),
    verify: (bloc) => expect(bloc.state, isA<ActiveTimerHidden>()),
  );

  blocTest<ActiveTimerBloc, ActiveTimerState>(
    'reset (logout) volta ao estado escondido',
    build: () {
      when(() => watchActiveTimer(any())).thenAnswer(
        (_) => Stream.value(Right<Failure, ActiveTimerEntity?>(activeOnTask)),
      );
      return build();
    },
    act: (bloc) async {
      bloc.add(const ActiveTimerStarted());
      await Future<void>.delayed(const Duration(milliseconds: 30));
      bloc.add(const ActiveTimerReset());
    },
    wait: const Duration(milliseconds: 60),
    verify: (bloc) => expect(bloc.state, isA<ActiveTimerHidden>()),
  );
}
