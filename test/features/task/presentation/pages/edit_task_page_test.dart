import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/presentation/pages/edit_task_args.dart';
import 'package:meu_tempo/features/task/presentation/pages/edit_task_page.dart';

void main() {
  final today = DateTime(2026, 7, 21);

  const lists = [
    TaskListEntity(id: 'inbox', name: 'Entrada', isDefault: true),
    TaskListEntity(id: 'work', name: 'Trabalho'),
  ];

  const candidates = [
    ParentCandidate(id: 'm1', title: 'Lançar app', path: 'tarefa mãe'),
  ];

  TaskEntity leaf({bool isDone = false}) => TaskEntity(
        id: 't1',
        title: 'Estudar',
        listId: 'inbox',
        createdAt: today,
        estimatedMinutes: 30,
        importance: ImportanceEnum.min,
        dueDate: today,
        isDone: isDone,
      );

  TaskEntity mother() => TaskEntity(
        id: 'm0',
        title: 'Projeto',
        listId: 'inbox',
        createdAt: today,
        hasChildren: true,
      );

  EditTaskArgs args(TaskEntity task, {String parentLabel = ''}) => EditTaskArgs(
        task: task,
        lists: lists,
        parentCandidates: candidates,
        currentParentLabel: parentLabel,
      );

  void setView(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  // Empurra a página e captura o EditTaskResult devolvido pelo pop (Salvar).
  Future<EditTaskResult?> pushPage(
    WidgetTester tester,
    EditTaskArgs a,
  ) async {
    EditTaskResult? result;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async => result = await Navigator.of(ctx)
                .push<EditTaskResult>(MaterialPageRoute(
              builder: (_) => EditTaskPage(args: a, today: today),
            )),
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return result;
  }

  group('renderização condicional', () {
    testWidgets('folha mostra todas as seções', (tester) async {
      setView(tester);
      await pushPage(tester, args(leaf()));

      expect(find.text('Lista'), findsOneWidget);
      expect(find.text('Tarefa mãe'), findsOneWidget);
      expect(find.text('Tempo estimado'), findsOneWidget);
      expect(find.text('Importância'), findsOneWidget);
      expect(find.text('Prazo'), findsOneWidget);
      expect(find.text('Concluída'), findsOneWidget);
      expect(find.text('Ajustar tempo gasto'), findsOneWidget);
    });

    testWidgets('mãe oculta as seções exclusivas de folha', (tester) async {
      setView(tester);
      await pushPage(tester, args(mother()));

      expect(find.text('Lista'), findsOneWidget);
      expect(find.text('Tarefa mãe'), findsOneWidget);
      expect(find.text('Tempo estimado'), findsNothing);
      expect(find.text('Importância'), findsNothing);
      expect(find.text('Concluída'), findsNothing);
      expect(find.text('Ajustar tempo gasto'), findsNothing);
    });

    testWidgets('mostra o breadcrumb da mãe atual', (tester) async {
      setView(tester);
      await pushPage(tester, args(leaf(), parentLabel: 'Projeto'));

      expect(find.text('Projeto'), findsOneWidget);
    });
  });

  group('salvar', () {
    testWidgets('devolve os campos atuais sem mudanças de flag', (tester) async {
      setView(tester);
      EditTaskResult? captured;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async => captured = await Navigator.of(ctx)
                  .push<EditTaskResult>(MaterialPageRoute(
                builder: (_) => EditTaskPage(args: args(leaf()), today: today),
              )),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.title, 'Estudar');
      expect(captured!.listId, 'inbox');
      expect(captured!.parentChanged, isFalse);
      expect(captured!.doneChanged, isFalse);
      expect(captured!.estimatedMinutes, 30);
    });

    testWidgets('trocar a lista reflete no listId do resultado', (tester) async {
      setView(tester);
      EditTaskResult? captured;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async => captured = await Navigator.of(ctx)
                  .push<EditTaskResult>(MaterialPageRoute(
                builder: (_) => EditTaskPage(args: args(leaf()), today: today),
              )),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Trabalho'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(captured!.listId, 'work');
    });

    testWidgets('marcar Concluída seta doneChanged', (tester) async {
      setView(tester);
      EditTaskResult? captured;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async => captured = await Navigator.of(ctx)
                  .push<EditTaskResult>(MaterialPageRoute(
                builder: (_) => EditTaskPage(args: args(leaf()), today: today),
              )),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(captured!.doneChanged, isTrue);
      expect(captured!.isDone, isTrue);
    });

    testWidgets('escolher nova mãe seta parentChanged e newParentId',
        (tester) async {
      setView(tester);
      EditTaskResult? captured;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async => captured = await Navigator.of(ctx)
                  .push<EditTaskResult>(MaterialPageRoute(
                builder: (_) => EditTaskPage(args: args(leaf()), today: today),
              )),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      // Abre o picker pelo botão de mãe e escolhe o candidato.
      await tester.tap(find.text('Nenhuma (é tarefa mãe)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lançar app'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(captured!.parentChanged, isTrue);
      expect(captured!.newParentId, 'm1');
    });
  });
}
