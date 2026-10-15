import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/core/ui/app_list_skeleton.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/recurring_task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/weekday_enum.dart';
import 'package:meu_tempo/features/task/presentation/bloc/recurring_task_bloc.dart';
import 'package:meu_tempo/features/task/presentation/pages/recurring_tasks_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockRecurringTaskBloc
    extends MockBloc<RecurringTaskEvent, RecurringTaskState>
    implements RecurringTaskBloc {}

void main() {
  late _MockRecurringTaskBloc bloc;

  const lists = [
    TaskListEntity(id: 'inbox', name: 'Entrada', isDefault: true),
    TaskListEntity(id: 'work', name: 'Trabalho'),
  ];

  final academia = RecurringTaskEntity(
    id: 'r1',
    title: 'Academia',
    listId: 'work',
    estimatedMinutes: 60,
    importance: ImportanceEnum.high,
    weekdays: {WeekdayEnum.monday, WeekdayEnum.wednesday, WeekdayEnum.friday},
    createdAt: DateTime(2026, 10, 1),
  );
  final lerEmails = RecurringTaskEntity(
    id: 'r2',
    title: 'Ler e-mails',
    listId: 'work',
    estimatedMinutes: 15,
    importance: ImportanceEnum.low,
    weekdays: WeekdayEnum.values.toSet(),
    createdAt: DateTime(2026, 10, 1),
  );
  final reuniao = RecurringTaskEntity(
    id: 'r3',
    title: 'Reunião semanal',
    listId: 'work',
    estimatedMinutes: 60,
    importance: ImportanceEnum.max,
    weekdays: {},
    createdAt: DateTime(2026, 10, 1),
  );

  late RecurringTaskLoaded loaded;

  setUpAll(() {
    registerFallbackValue(const RecurringTasksStarted());
  });

  setUp(() {
    bloc = _MockRecurringTaskBloc();
    loaded = RecurringTaskLoaded([academia, lerEmails, reuniao], lists);
  });

  Widget harness() => MaterialApp(
    theme: AppTheme.dark,
    home: BlocProvider<RecurringTaskBloc>.value(
      value: bloc,
      child: const RecurringTasksPage(),
    ),
  );

  void setView(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpWithEffect(
    WidgetTester tester,
    RecurringTaskEffect effect,
  ) async {
    setView(tester);
    whenListen(
      bloc,
      Stream<RecurringTaskState>.fromIterable([effect, loaded]),
      initialState: loaded,
    );
    await tester.pumpWidget(harness());
    await tester.pump();
    await tester.pump();
  }

  testWidgets('mostra skeleton ao carregar', (tester) async {
    setView(tester);
    when(() => bloc.state).thenReturn(const RecurringTaskLoading());

    await tester.pumpWidget(harness());

    expect(find.byType(AppListSkeleton), findsOneWidget);
  });

  testWidgets('mostra estado vazio com botão de criar', (tester) async {
    setView(tester);
    when(() => bloc.state).thenReturn(const RecurringTaskLoaded([], lists));

    await tester.pumpWidget(harness());

    expect(find.text('Nenhuma tarefa recorrente'), findsOneWidget);
    expect(find.text('Nova tarefa recorrente'), findsOneWidget);
    expect(find.text('Nova'), findsNothing);
  });

  testWidgets('mostra os cartões com resumo dos dias, tempo, importância e '
      'lista', (tester) async {
    setView(tester);
    when(() => bloc.state).thenReturn(loaded);

    await tester.pumpWidget(harness());

    expect(find.text('Academia'), findsOneWidget);
    expect(find.text('Seg · Qua · Sex'), findsOneWidget);
    expect(find.text('1h'), findsNWidgets(2));
    expect(find.text('Alta'), findsOneWidget);
    expect(find.text('Trabalho'), findsNWidgets(3));
    expect(find.text('Todo dia'), findsOneWidget);
    expect(find.text('Sem dia fixo'), findsOneWidget);
    expect(find.text('Máxima'), findsOneWidget);
    expect(find.text('Adicionar hoje'), findsNWidgets(3));
  });

  testWidgets('mostra erro e tenta de novo', (tester) async {
    setView(tester);
    when(() => bloc.state).thenReturn(
      const RecurringTaskError('Sem conexão. Verifique a internet.'),
    );

    await tester.pumpWidget(harness());
    expect(find.text('Sem conexão. Verifique a internet.'), findsOneWidget);

    await tester.tap(find.text('Tentar de novo'));
    await tester.pump();

    verify(() => bloc.add(const RecurringTasksStarted())).called(1);
  });

  testWidgets('Adicionar hoje despacha o evento sem confirmação', (
    tester,
  ) async {
    setView(tester);
    when(() => bloc.state).thenReturn(loaded);

    await tester.pumpWidget(harness());
    await tester.tap(find.text('Adicionar hoje').first);
    await tester.pump();

    verify(() => bloc.add(RecurringTaskAddedToday(academia))).called(1);
  });

  testWidgets('mostra snackbar ao adicionar hoje', (tester) async {
    await pumpWithEffect(tester, const RecurringTaskAddedTodayDone(1));

    expect(find.text('Tarefa adicionada para hoje'), findsOneWidget);
  });

  testWidgets('diálogo de pendente cria com confirmed true', (tester) async {
    await pumpWithEffect(tester, RecurringTaskConfirmRequested(academia, 1));

    expect(find.textContaining('Criar mesmo assim?'), findsOneWidget);

    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    verify(
      () => bloc.add(RecurringTaskAddedToday(academia, confirmed: true)),
    ).called(1);
  });

  testWidgets('cancelar no diálogo não cria', (tester) async {
    await pumpWithEffect(tester, RecurringTaskConfirmRequested(academia, 1));

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verifyNever(
      () => bloc.add(RecurringTaskAddedToday(academia, confirmed: true)),
    );
  });

  testWidgets('mostra snackbar de falha', (tester) async {
    await pumpWithEffect(
      tester,
      const RecurringTaskActionFailed('Algo deu errado. Tente novamente.', 1),
    );

    expect(find.text('Algo deu errado. Tente novamente.'), findsOneWidget);
  });

  testWidgets('arrastar exclui e desfazer restaura', (tester) async {
    setView(tester);
    final controller = StreamController<RecurringTaskState>();
    addTearDown(controller.close);
    whenListen(bloc, controller.stream, initialState: loaded);
    when(() => bloc.add(RecurringTaskDeleted(academia))).thenAnswer(
      (_) => controller.add(RecurringTaskLoaded([lerEmails, reuniao], lists)),
    );

    await tester.pumpWidget(harness());
    await tester.drag(find.text('Academia'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    verify(() => bloc.add(RecurringTaskDeleted(academia))).called(1);
    expect(find.text('Academia'), findsNothing);

    controller
      ..add(RecurringTaskDeletedDone(academia, 1))
      ..add(RecurringTaskLoaded([lerEmails, reuniao], lists));
    await tester.pump();
    await tester.pump();

    expect(find.text('Tarefa recorrente excluída'), findsOneWidget);

    // Espera a animação de entrada do snackbar terminar.
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Desfazer'));
    await tester.pump();

    verify(() => bloc.add(RecurringTaskRestored(academia))).called(1);
  });

  testWidgets('tocar no cartão abre a edição e despacha RecurringTaskEdited', (
    tester,
  ) async {
    setView(tester);
    when(() => bloc.state).thenReturn(loaded);

    await tester.pumpWidget(harness());
    await tester.tap(find.text('Academia'));
    await tester.pumpAndSettle();

    expect(find.text('Editar tarefa recorrente'), findsOneWidget);

    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    final event =
        verify(() => bloc.add(captureAny())).captured.single
            as RecurringTaskEdited;
    expect(event.params.original, academia);
    expect(event.params.title, 'Academia');
  });

  testWidgets('FAB Nova abre o formulário vazio e despacha '
      'RecurringTaskCreated', (tester) async {
    setView(tester);
    when(() => bloc.state).thenReturn(loaded);

    await tester.pumpWidget(harness());
    await tester.tap(find.text('Nova'));
    await tester.pumpAndSettle();

    expect(find.text('Nova tarefa recorrente'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Ler');
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    verify(
      () => bloc.add(
        const RecurringTaskCreated(
          title: 'Ler',
          listId: 'inbox',
          estimatedMinutes: 30,
          importance: ImportanceEnum.min,
          weekdays: {},
        ),
      ),
    ).called(1);
  });

  testWidgets('sair da tela esconde o Desfazer', (tester) async {
    setView(tester);
    final controller = StreamController<RecurringTaskState>();
    addTearDown(controller.close);
    whenListen(bloc, controller.stream, initialState: loaded);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BlocProvider<RecurringTaskBloc>.value(
                  value: bloc,
                  child: const RecurringTasksPage(),
                ),
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    controller
      ..add(RecurringTaskDeletedDone(academia, 1))
      ..add(loaded);
    await tester.pump();
    await tester.pump();
    expect(find.text('Tarefa recorrente excluída'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Tarefa recorrente excluída'), findsNothing);
  });
}
