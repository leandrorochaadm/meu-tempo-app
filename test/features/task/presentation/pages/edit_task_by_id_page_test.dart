import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_tempo/core/router/routes.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/task_edit_context.dart';
import 'package:meu_tempo/features/task/domain/entities/task_edit_target_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/presentation/bloc/active_timer_bloc.dart';
import 'package:meu_tempo/features/task/presentation/bloc/edit_task_by_id_bloc.dart';
import 'package:meu_tempo/features/task/presentation/pages/edit_task_by_id_page.dart';
import 'package:meu_tempo/features/task/presentation/pages/edit_task_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockEditByIdBloc extends MockBloc<EditTaskByIdEvent, EditTaskByIdState>
    implements EditTaskByIdBloc {}

class _MockActiveTimerBloc extends MockBloc<ActiveTimerEvent, ActiveTimerState>
    implements ActiveTimerBloc {}

const _result = EditTaskResult(
  title: 'Novo',
  estimatedMinutes: 30,
  dueDate: null,
  importance: null,
  listId: 'inbox',
  newParentId: null,
  parentChanged: false,
  isDone: false,
  doneChanged: false,
);

void main() {
  late _MockEditByIdBloc editBloc;
  late _MockActiveTimerBloc timerBloc;

  final target = TaskEditTargetEntity(
    editContext: TaskEditContext(
      task: TaskEntity(
        id: 't1',
        title: 'Tela de login',
        listId: 'inbox',
        createdAt: DateTime(2026, 10, 7),
      ),
      parentCandidates: const [],
      currentParentLabel: '',
    ),
    lists: const [TaskListEntity(id: 'inbox', name: 'Entrada')],
  );

  setUpAll(() {
    registerFallbackValue(const EditTaskByIdStarted('x'));
    registerFallbackValue(const ActiveTimerStarted());
  });

  setUp(() {
    editBloc = _MockEditByIdBloc();
    timerBloc = _MockActiveTimerBloc();
    when(() => timerBloc.state).thenReturn(const ActiveTimerHidden());
  });

  Widget harness() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: ElevatedButton(
              onPressed: () => context.push(Routes.timerTarget),
              child: const Text('abrir'),
            ),
          ),
        ),
        GoRoute(
          path: Routes.timerTarget,
          builder: (_, _) => BlocProvider<EditTaskByIdBloc>.value(
            value: editBloc,
            child: const EditTaskByIdPage(taskId: 't1'),
          ),
        ),
        GoRoute(
          path: Routes.editTask,
          builder: (context, _) => Scaffold(
            body: Column(
              children: [
                ElevatedButton(
                  onPressed: () => context.pop(_result),
                  child: const Text('salvar'),
                ),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('voltar'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    return BlocProvider<ActiveTimerBloc>.value(
      value: timerBloc,
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    );
  }

  Future<void> openPage(WidgetTester tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('abrir'));
    // The skeleton animates forever (no pumpAndSettle): step frame by frame.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  void emitReady() => whenListen(
        editBloc,
        Stream<EditTaskByIdState>.value(EditTaskByIdReady(target)),
        initialState: const EditTaskByIdLoading(),
      );

  testWidgets('asks to load by id', (tester) async {
    when(() => editBloc.state).thenReturn(const EditTaskByIdLoading());

    await openPage(tester);

    verify(() => editBloc.add(const EditTaskByIdStarted('t1'))).called(1);
  });

  testWidgets('ready: opens the editor, saves on submit and closes',
      (tester) async {
    emitReady();
    await openPage(tester);
    expect(find.text('salvar'), findsOneWidget);

    await tester.tap(find.text('salvar'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    verify(() => timerBloc.add(const ActiveTimerEditSubmitted('t1', _result)))
        .called(1);
    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets('going back without saving does not write and closes',
      (tester) async {
    emitReady();
    await openPage(tester);

    await tester.tap(find.text('voltar'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    verifyNever(() => timerBloc.add(any()));
    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets('deleted task shows a notice', (tester) async {
    when(() => editBloc.state).thenReturn(const EditTaskByIdNotFound());

    await openPage(tester);

    expect(find.text('Tarefa não encontrada'), findsOneWidget);
  });

  testWidgets('error shows the message', (tester) async {
    when(() => editBloc.state).thenReturn(
      const EditTaskByIdError('Sem conexão. Verifique a internet.'),
    );

    await openPage(tester);

    expect(find.text('Sem conexão. Verifique a internet.'), findsOneWidget);
  });
}
