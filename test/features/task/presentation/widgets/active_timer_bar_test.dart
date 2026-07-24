import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_tempo/core/router/app_router.dart';
import 'package:meu_tempo/core/router/routes.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/task/presentation/pages/edit_task_page.dart';
import 'package:meu_tempo/features/auth/domain/entities/user_entity.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_tempo/features/task/domain/entities/task_edit_context.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/presentation/bloc/active_timer_bloc.dart';
import 'package:meu_tempo/features/task/presentation/widgets/active_timer_bar.dart';
import 'package:mocktail/mocktail.dart';

class _MockActiveTimerBloc extends MockBloc<ActiveTimerEvent, ActiveTimerState>
    implements ActiveTimerBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late _MockActiveTimerBloc timerBloc;
  late _MockAuthBloc authBloc;

  final leaf = TaskEntity(
    id: 't1',
    title: 'Fazer telas de login',
    listId: 'inbox',
    createdAt: DateTime(2026, 7, 22),
  );
  final running = ActiveTimerRunning(
    title: leaf.title,
    ancestryLabel: 'Lançar app › App',
    startedAt: DateTime(2026, 7, 22, 10),
    editContext: TaskEditContext(
      task: leaf,
      parentCandidates: const [],
      currentParentLabel: 'Lançar app › App',
    ),
    lists: const [],
  );

  setUpAll(() {
    registerFallbackValue(const ActiveTimerStarted());
  });

  setUp(() {
    timerBloc = _MockActiveTimerBloc();
    authBloc = _MockAuthBloc();
    when(() => authBloc.state).thenReturn(
      const AuthAuthenticated(UserEntity(uid: 'u1', email: 'a@b.com')),
    );
  });

  Widget harness() => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: authBloc),
              BlocProvider<ActiveTimerBloc>.value(value: timerBloc),
            ],
            child: const Align(
              alignment: Alignment.bottomCenter,
              child: ActiveTimerBar(),
            ),
          ),
        ),
      );

  // Harness com GoRouter: a rota de edição devolve um EditTaskResult ao "salvar",
  // permitindo testar a navegação do botão Editar e o guard de toque duplo.
  Widget routerHarness() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ActiveTimerBar(),
            ),
          ),
        ),
        GoRoute(
          path: Routes.editTask,
          builder: (context, _) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.pop(
                  const EditTaskResult(
                    title: 'Novo',
                    estimatedMinutes: 30,
                    dueDate: null,
                    importance: null,
                    listId: 'inbox',
                    newParentId: null,
                    parentChanged: false,
                    isDone: false,
                    doneChanged: false,
                  ),
                ),
                child: const Text('salvar'),
              ),
            ),
          ),
        ),
      ],
    );
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<ActiveTimerBloc>.value(value: timerBloc),
      ],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    );
  }

  // Regressão: monta a barra como em produção (ShellRoute + AppShell), ou seja,
  // dentro do Navigator raiz mas SEM um Scaffold envolvendo-a. Garante que os
  // Tooltip (Overlay) e o diálogo (Navigator) funcionam nesse arranjo real.
  Widget shellHarness() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (_, _, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
            ),
          ],
        ),
      ],
    );
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<ActiveTimerBloc>.value(value: timerBloc),
      ],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    );
  }

  testWidgets(
    'no arranjo real (AppShell) os tooltips e o diálogo têm Overlay/Navigator',
    (tester) async {
      when(() => timerBloc.state).thenReturn(running);
      await tester.pumpWidget(shellHarness());
      await tester.pump();

      // Renderizou sem exceção de Overlay e mostra a barra.
      expect(tester.takeException(), isNull);
      expect(find.text('Fazer telas de login'), findsOneWidget);

      // O diálogo (que exige Navigator) abre normalmente.
      await tester.tap(find.byTooltip('Concluir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Concluir tarefa?'), findsOneWidget);
    },
  );

  testWidgets('escondida quando não há cronômetro rodando', (tester) async {
    when(() => timerBloc.state).thenReturn(const ActiveTimerHidden());
    await tester.pumpWidget(harness());

    expect(find.byType(IconButton), findsNothing);
    expect(find.text('Fazer telas de login'), findsNothing);
  });

  testWidgets('mostra nome, trilha e o tempo quando rodando', (tester) async {
    when(() => timerBloc.state).thenReturn(running);
    await tester.pumpWidget(harness());

    expect(find.text('Fazer telas de login'), findsOneWidget);
    expect(find.text('Lançar app › App'), findsOneWidget);
    // Contador ao vivo hh:mm:ss (>= 0).
    expect(find.textContaining(':'), findsOneWidget);
    // Três ações: editar, concluir, parar.
    expect(find.byType(IconButton), findsNWidgets(3));
  });

  testWidgets('tocar em Parar dispara ActiveTimerStopRequested',
      (tester) async {
    when(() => timerBloc.state).thenReturn(running);
    await tester.pumpWidget(harness());

    await tester.tap(find.byTooltip('Parar'));
    await tester.pump();

    verify(() => timerBloc.add(const ActiveTimerStopRequested())).called(1);
  });

  testWidgets('Concluir pede confirmação antes de disparar o evento',
      (tester) async {
    when(() => timerBloc.state).thenReturn(running);
    await tester.pumpWidget(harness());

    await tester.tap(find.byTooltip('Concluir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Diálogo de confirmação aparece; nenhum evento ainda.
    expect(find.text('Concluir tarefa?'), findsOneWidget);
    verifyNever(
      () => timerBloc.add(any(that: isA<ActiveTimerCompleteRequested>())),
    );

    // Confirma → dispara o evento.
    await tester.tap(find.widgetWithText(FilledButton, 'Concluir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    verify(() => timerBloc.add(const ActiveTimerCompleteRequested('t1')))
        .called(1);
  });

  testWidgets('mostra snackbar quando uma ação falha, sem sumir com a barra',
      (tester) async {
    whenListen(
      timerBloc,
      Stream<ActiveTimerState>.fromIterable([
        const ActiveTimerActionFailed('Sem conexão. Verifique a internet.'),
      ]),
      initialState: running,
    );
    await tester.pumpWidget(harness());
    await tester.pump(); // processa o evento de falha
    await tester.pump(const Duration(milliseconds: 300)); // anima o snackbar

    expect(find.text('Sem conexão. Verifique a internet.'), findsOneWidget);
    // A barra continua visível (buildWhen ignora o estado de falha).
    expect(find.text('Fazer telas de login'), findsOneWidget);
  });

  testWidgets('cancelar a confirmação não conclui', (tester) async {
    when(() => timerBloc.state).thenReturn(running);
    await tester.pumpWidget(harness());

    await tester.tap(find.byTooltip('Concluir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    verifyNever(
      () => timerBloc.add(any(that: isA<ActiveTimerCompleteRequested>())),
    );
  });

  testWidgets('toque duplo em Concluir abre apenas um diálogo (guard)',
      (tester) async {
    when(() => timerBloc.state).thenReturn(running);
    await tester.pumpWidget(harness());

    // Dois toques sem pump entre eles: o 2º cai no guard `_busy`.
    await tester.tap(find.byTooltip('Concluir'));
    await tester.tap(find.byTooltip('Concluir'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Concluir tarefa?'), findsOneWidget);
  });

  testWidgets('Editar navega e, ao salvar, dispara ActiveTimerEditSubmitted',
      (tester) async {
    when(() => timerBloc.state).thenReturn(running);
    await tester.pumpWidget(routerHarness());
    await tester.pump();

    await tester.tap(find.byTooltip('Editar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Está na tela de edição do harness.
    expect(find.text('salvar'), findsOneWidget);

    await tester.tap(find.text('salvar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    verify(() => timerBloc.add(any(that: isA<ActiveTimerEditSubmitted>())))
        .called(1);
  });
}
