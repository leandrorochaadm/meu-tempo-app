import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/constants/app_defaults.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/auth/domain/entities/user_entity.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/prioritized_leaf.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/presentation/bloc/task_list_bloc.dart';
import 'package:meu_tempo/features/task/presentation/pages/task_list_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskListBloc extends MockBloc<TaskListEvent, TaskListState>
    implements TaskListBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late _MockTaskListBloc taskBloc;
  late _MockAuthBloc authBloc;

  setUp(() {
    taskBloc = _MockTaskListBloc();
    authBloc = _MockAuthBloc();
    when(() => authBloc.state).thenReturn(
      const AuthAuthenticated(UserEntity(uid: 'u1', email: 'a@b.com')),
    );
  });

  Widget harness() => MaterialApp(
        theme: AppTheme.dark,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<TaskListBloc>.value(value: taskBloc),
            BlocProvider<AuthBloc>.value(value: authBloc),
          ],
          child: const TaskListPage(),
        ),
      );

  void setView(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('mostra empty state quando não há tarefas', (tester) async {
    setView(tester);
    when(() => taskBloc.state).thenReturn(const TaskListEmpty());

    await tester.pumpWidget(harness());

    expect(find.text('Sua lista está vazia'), findsOneWidget);
  });

  testWidgets('FAB revela a criação rápida (campo no topo)', (tester) async {
    setView(tester);
    when(() => taskBloc.state).thenReturn(const TaskListEmpty());

    await tester.pumpWidget(harness());
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('digitar título e confirmar dispara TaskCreated', (tester) async {
    setView(tester);
    when(() => taskBloc.state).thenReturn(const TaskListEmpty());

    await tester.pumpWidget(harness());
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Estudar Flutter');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    verify(() => taskBloc.add(const TaskCreated('Estudar Flutter'))).called(1);
  });

  // --- Visão por prioridade (padrão): CRUD/tempo da folha ---

  final leaf = PrioritizedLeaf(
    task: TaskEntity(
      id: 't1',
      title: 'Estudar Flutter',
      listId: 'l1',
      createdAt: DateTime(2026, 7, 21),
      estimatedMinutes: 120,
      dueDate: DateTime(2026, 7, 21),
      spentMinutes: 45,
    ),
    priority: 42,
    ancestryLabel: '',
  );

  TaskListLoaded loadedWithLeaf() =>
      TaskListLoaded(const [], prioritized: [leaf]);

  testWidgets('concluir na visão por prioridade dispara CompleteToggled',
      (tester) async {
    setView(tester);
    when(() => taskBloc.state).thenReturn(loadedWithLeaf());

    await tester.pumpWidget(harness());
    await tester.tap(find.byIcon(Icons.circle_outlined));
    await tester.pump();

    verify(() => taskBloc.add(const CompleteToggled(taskId: 't1', done: true)))
        .called(1);
  });

  testWidgets('concluir mostra snackbar com ação de desfazer', (tester) async {
    setView(tester);
    when(() => taskBloc.state).thenReturn(loadedWithLeaf());

    await tester.pumpWidget(harness());
    await tester.tap(find.byIcon(Icons.circle_outlined));
    await tester.pump();

    expect(find.text('Desfazer'), findsOneWidget);
  });

  testWidgets('snackbar de desfazer fica visível por 10 segundos',
      (tester) async {
    setView(tester);
    when(() => taskBloc.state).thenReturn(loadedWithLeaf());

    await tester.pumpWidget(harness());
    await tester.tap(find.byIcon(Icons.circle_outlined));
    await tester.pump();

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.duration, AppDefaults.undoSnackbarDuration);
    expect(snackBar.duration, const Duration(seconds: 10));
    // persist deve ser false: no Flutter 3.41+ ele assume true quando há action,
    // o que ignora o duration e deixa o snackbar fixo na tela (regressão).
    expect(snackBar.persist, isFalse);
  });

  testWidgets('iniciar cronômetro na prioridade dispara TimerStartRequested',
      (tester) async {
    setView(tester);
    when(() => taskBloc.state).thenReturn(loadedWithLeaf());

    await tester.pumpWidget(harness());
    await tester.tap(find.text('Iniciar'));
    await tester.pump();

    verify(() => taskBloc.add(
          const TimerStartRequested(taskId: 't1', isLeaf: true),
        )).called(1);
  });

  // --- Filtro por lista (ListFilterBar) ---

  const twoLists = [
    TaskListEntity(id: 'inbox', name: 'Entrada', isDefault: true),
    TaskListEntity(id: 'work', name: 'Profissional'),
  ];

  testWidgets('mostra o chip de filtro com 2+ listas', (tester) async {
    setView(tester);
    when(() => taskBloc.state).thenReturn(
      TaskListLoaded(const [], prioritized: [leaf], lists: twoLists),
    );

    await tester.pumpWidget(harness());

    expect(find.text('Todas as listas'), findsOneWidget);
  });

  testWidgets('oculta o chip de filtro com menos de 2 listas', (tester) async {
    setView(tester);
    when(() => taskBloc.state).thenReturn(
      TaskListLoaded(
        const [],
        prioritized: [leaf],
        lists: const [TaskListEntity(id: 'inbox', name: 'Entrada', isDefault: true)],
      ),
    );

    await tester.pumpWidget(harness());

    expect(find.text('Todas as listas'), findsNothing);
  });

  testWidgets('trocar de lista no seletor dispara ListFilterChanged',
      (tester) async {
    setView(tester);
    when(() => taskBloc.state).thenReturn(
      TaskListLoaded(const [], prioritized: [leaf], lists: twoLists),
    );

    await tester.pumpWidget(harness());
    await tester.tap(find.text('Todas as listas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profissional'));
    await tester.pumpAndSettle();

    verify(() => taskBloc.add(const ListFilterChanged('work'))).called(1);
  });

  testWidgets('escolher "Todas as listas" dispara ListFilterChanged(null)',
      (tester) async {
    setView(tester);
    when(() => taskBloc.state).thenReturn(
      const TaskListLoaded(
        [],
        prioritized: [],
        lists: twoLists,
        selectedListId: 'work',
      ),
    );

    await tester.pumpWidget(harness());
    // O chip mostra a lista atual ("Profissional"); abre o seletor.
    await tester.tap(find.text('Profissional'));
    await tester.pumpAndSettle();
    // Opção "Todas as listas" dentro do bottom sheet.
    await tester.tap(find.text('Todas as listas'));
    await tester.pumpAndSettle();

    verify(() => taskBloc.add(const ListFilterChanged(null))).called(1);
  });

  testWidgets('empty-filtrado mostra aviso mantendo o chip', (tester) async {
    setView(tester);
    when(() => taskBloc.state).thenReturn(
      const TaskListLoaded(
        [],
        prioritized: [],
        lists: twoLists,
        selectedListId: 'work',
      ),
    );

    await tester.pumpWidget(harness());

    expect(find.text('Nenhuma tarefa nesta lista'), findsOneWidget);
    // O chip continua visível, exibindo a lista filtrada.
    expect(find.text('Profissional'), findsOneWidget);
  });
}
