import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/constants/app_defaults.dart';
import 'package:meu_tempo/core/theme/app_colors.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/task_node.dart';
import 'package:meu_tempo/features/task/presentation/widgets/task_node_tile.dart';

void main() {
  final today = DateTime(2026, 7, 21);

  TaskEntity task(String id, String title) => TaskEntity(
    id: id,
    title: title,
    listId: 'l1',
    createdAt: today,
    estimatedMinutes: 60,
    dueDate: today,
    spentMinutes: 30,
  );

  // Folha = nó sem filhas.
  TaskNode leafNode() => TaskNode(task: task('leaf', 'Folha'), level: 0);

  // Mãe = tarefa com `hasChildren` (como o banco grava) e uma filha na árvore.
  // Não é folha → sem conclusão por swipe, sem cronômetro.
  TaskNode parentNode() => TaskNode(
    task: TaskEntity(
      id: 'parent',
      title: 'Mãe',
      listId: 'l1',
      createdAt: today,
      hasChildren: true,
    ),
    level: 0,
    children: [TaskNode(task: task('child', 'Filha'), level: 1)],
  );

  // Mãe cuja única filha está em OUTRA lista: o filtro por lista a remove da
  // coleção, então o nó chega sem `children`. Ela continua não sendo folha.
  TaskNode parentWithFilteredChild() => TaskNode(
    task: TaskEntity(
      id: 'parent',
      title: 'Mãe',
      listId: 'l1',
      createdAt: today,
      hasChildren: true,
    ),
    level: 0,
  );

  TaskNode netaLeafNode({int? rank}) => TaskNode(
    task: task('neta', 'Neta'),
    level: AppDefaults.maxTaskLevel,
    rank: rank,
  );

  TaskNode doneLeafNode() => TaskNode(
    task: TaskEntity(
      id: 'leaf',
      title: 'Folha',
      listId: 'l1',
      createdAt: today,
      estimatedMinutes: 60,
      dueDate: today,
      spentMinutes: 30,
      isDone: true,
    ),
    level: 0,
  );

  late bool doneTapped;
  bool? doneValue;
  late bool editTapped;
  late bool deleteTapped;
  bool? timerStart;
  int? addedMinutes;
  late bool addSubtaskTapped;

  setUp(() {
    timerStart = null;
    addedMinutes = null;
    addSubtaskTapped = false;
    doneTapped = false;
    doneValue = null;
    editTapped = false;
    deleteTapped = false;
  });

  Widget harness(
    TaskNode node, {
    bool isActive = false,
    DateTime? activeStartedAt,
  }) => MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: TaskNodeTile(
        node: node,
        isActive: isActive,
        activeStartedAt: activeStartedAt,
        onAddSubtask: (_) => addSubtaskTapped = true,
        onToggleTimer: (_, start) => timerStart = start,
        onAddTime: (_, minutes) => addedMinutes = minutes,
        onToggleDone: (_, done) {
          doneTapped = true;
          doneValue = done;
        },
        onDelete: (_) => deleteTapped = true,
        onEdit: (_) => editTapped = true,
        onMove: (_) {},
      ),
    ),
  );

  void phoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
  }

  testWidgets('folha: arrastar para a direita conclui', (tester) async {
    await tester.pumpWidget(harness(leafNode()));

    await tester.drag(find.text('Folha'), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(doneTapped, isTrue);
  });

  group('concluir e reabrir a folha', () {
    testWidgets('folha aberta oferece Concluir e envia done = true', (
      tester,
    ) async {
      await tester.pumpWidget(harness(leafNode()));

      await tester.tap(find.byTooltip('Concluir'));

      expect(doneValue, isTrue);
    });

    testWidgets('folha concluída oferece Reabrir e envia done = false', (
      tester,
    ) async {
      await tester.pumpWidget(harness(doneLeafNode()));

      expect(find.byTooltip('Reabrir'), findsOneWidget);
      await tester.tap(find.byTooltip('Reabrir'));

      expect(doneValue, isFalse);
    });

    testWidgets('arrastar a folha concluída para a direita reabre', (
      tester,
    ) async {
      await tester.pumpWidget(harness(doneLeafNode()));

      await tester.drag(find.text('Folha'), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(doneValue, isFalse);
    });

    testWidgets('botão de concluir tem alvo de toque de 48 dp', (tester) async {
      await tester.pumpWidget(harness(leafNode()));

      expect(
        tester
            .getSize(find.widgetWithIcon(IconButton, Icons.circle_outlined))
            .height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('mãe não tem botão de concluir/reabrir', (tester) async {
      await tester.pumpWidget(harness(parentNode()));

      expect(find.byTooltip('Concluir'), findsNothing);
      expect(find.byTooltip('Reabrir'), findsNothing);
    });
  });

  testWidgets('mãe: arrastar para a direita NÃO conclui (gate isLeaf)', (
    tester,
  ) async {
    await tester.pumpWidget(harness(parentNode()));

    await tester.drag(find.text('Mãe'), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(doneTapped, isFalse);
  });

  testWidgets('mãe: arrastar para a esquerda edita', (tester) async {
    await tester.pumpWidget(harness(parentNode()));

    await tester.drag(find.text('Mãe'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(editTapped, isTrue);
  });

  testWidgets('mãe: clique longo exclui', (tester) async {
    await tester.pumpWidget(harness(parentNode()));

    await tester.longPress(find.text('Mãe'));
    await tester.pumpAndSettle();

    expect(deleteTapped, isTrue);
  });

  // Container do card = o único com BoxDecoration que tem borda esquerda.
  Color leftBorderColor(WidgetTester tester) {
    final container = tester
        .widgetList<Container>(find.byType(Container))
        .firstWhere((c) {
          final d = c.decoration;
          return d is BoxDecoration && d.border is Border;
        });
    final border = (container.decoration! as BoxDecoration).border! as Border;
    return border.left.color;
  }

  testWidgets('folha atrasada pinta a borda esquerda de warning', (
    tester,
  ) async {
    final node = TaskNode(
      task: task('leaf', 'Folha'),
      level: 0,
      isOverdue: true,
    );
    await tester.pumpWidget(harness(node));

    expect(leftBorderColor(tester), AppColors.dark.warning);
  });

  testWidgets('folha no prazo usa a cor de categoria do nível', (tester) async {
    await tester.pumpWidget(harness(leafNode()));

    expect(leftBorderColor(tester), AppColors.dark.categoryAt(0));
  });

  group('posição na fila (#rank)', () {
    testWidgets('folha com posição exibe #N ao lado do tempo', (tester) async {
      final node = TaskNode(task: task('leaf', 'Folha'), level: 0, rank: 3);
      await tester.pumpWidget(harness(node));

      expect(find.text('gasto 30min · #3'), findsOneWidget);
    });

    testWidgets('folha sem posição não exibe #', (tester) async {
      await tester.pumpWidget(harness(leafNode()));

      expect(find.text('gasto 30min'), findsOneWidget);
      expect(find.textContaining('#'), findsNothing);
    });

    testWidgets('mãe não exibe # (não entra na fila)', (tester) async {
      await tester.pumpWidget(harness(parentNode()));

      expect(find.textContaining('#'), findsNothing);
    });
  });

  group('mãe cuja filha foi removida pelo filtro de lista', () {
    testWidgets('não conclui por swipe (continua não sendo folha)', (
      tester,
    ) async {
      await tester.pumpWidget(harness(parentWithFilteredChild()));

      await tester.drag(find.text('Mãe'), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(doneTapped, isFalse);
    });

    testWidgets('não oferece cronômetro nem registro de tempo', (tester) async {
      await tester.pumpWidget(harness(parentWithFilteredChild()));

      // Ações de tempo existem só na folha (gate `node.isLeaf` no tile).
      expect(find.byTooltip('Iniciar cronômetro'), findsNothing);
      await openMenu(tester);
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Somar 30 min'), findsNothing);
    });

    testWidgets('segue editável e excluível', (tester) async {
      await tester.pumpWidget(harness(parentWithFilteredChild()));

      await tester.drag(find.text('Mãe'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(editTapped, isTrue);

      await tester.longPress(find.text('Mãe'));
      await tester.pumpAndSettle();
      expect(deleteTapped, isTrue);
    });
  });

  group('card compacto', () {
    testWidgets('folha com título de 1 linha tem no máximo 88 px de altura', (
      tester,
    ) async {
      phoneViewport(tester);
      await tester.pumpWidget(
        harness(leafNode(), isActive: true, activeStartedAt: DateTime.now()),
      );
      await tester.pump();

      expect(
        tester.getSize(find.byType(TaskNodeTile)).height,
        lessThanOrEqualTo(88),
      );
    });

    testWidgets('título longo aparece inteiro, sem overflow', (tester) async {
      phoneViewport(tester);
      const longTitle =
          'Preparar a apresentação completa do projeto para a reunião '
          'trimestral com a diretoria';
      final node = TaskNode(task: task('leaf', longTitle), level: 0);
      await tester.pumpWidget(harness(node));

      final text = tester.widget<Text>(find.text(longTitle));
      expect(text.maxLines, isNull);
      expect(text.overflow, isNull);
      expect(
        tester.getSize(find.text(longTitle)).height,
        greaterThanOrEqualTo(
          2 * AppTheme.dark.textTheme.titleMedium!.fontSize!,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '"Somar 30 min" fica no menu ⋮ da folha e não aparece no da mãe',
      (tester) async {
        await tester.pumpWidget(harness(leafNode()));
        await openMenu(tester);
        await tester.tap(find.text('Somar 30 min'));
        await tester.pumpAndSettle();
        expect(addedMinutes, AppDefaults.quickAddTimeMinutes);

        await tester.pumpWidget(harness(parentNode()));
        await openMenu(tester);
        expect(find.text('Editar'), findsOneWidget);
        expect(find.text('Somar 30 min'), findsNothing);
      },
    );

    testWidgets(
      'folha não mostra o "+" na linha e tem "Adicionar subtarefa" no ⋮',
      (tester) async {
        await tester.pumpWidget(harness(leafNode()));

        expect(find.byTooltip('Adicionar subtarefa'), findsNothing);
        await openMenu(tester);
        await tester.tap(find.text('Adicionar subtarefa'));
        await tester.pumpAndSettle();
        expect(addSubtaskTapped, isTrue);
      },
    );

    testWidgets('neta não tem "Adicionar subtarefa" no ⋮', (tester) async {
      await tester.pumpWidget(harness(netaLeafNode()));
      await openMenu(tester);

      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Adicionar subtarefa'), findsNothing);
      expect(find.text('Somar 30 min'), findsOneWidget);
    });

    testWidgets('mãe mantém o "+" na linha', (tester) async {
      await tester.pumpWidget(harness(parentNode()));

      expect(find.byTooltip('Adicionar subtarefa'), findsOneWidget);
      await tester.tap(find.byTooltip('Adicionar subtarefa'));
      expect(addSubtaskTapped, isTrue);

      await openMenu(tester);
      expect(find.text('Adicionar subtarefa'), findsNothing);
    });

    testWidgets('neta com cronômetro ativo não estoura a largura', (
      tester,
    ) async {
      phoneViewport(tester);
      await tester.pumpWidget(
        harness(
          netaLeafNode(rank: 12),
          isActive: true,
          activeStartedAt: DateTime.now(),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('tocar no ▶ da folha inicia o cronômetro e no ■ para', (
      tester,
    ) async {
      await tester.pumpWidget(harness(leafNode()));
      await tester.tap(find.byTooltip('Iniciar cronômetro'));
      expect(timerStart, isTrue);

      await tester.pumpWidget(
        harness(leafNode(), isActive: true, activeStartedAt: DateTime.now()),
      );
      await tester.tap(find.byTooltip('Parar cronômetro'));
      await tester.pump();
      expect(timerStart, isFalse);
    });

    testWidgets(
      'mãe mostra gasto e folhas concluídas na mesma linha, sem "est."',
      (tester) async {
        await tester.pumpWidget(harness(parentNode()));

        expect(find.text('gasto 30min · 0/1 concluídas'), findsOneWidget);
        expect(find.textContaining('est.'), findsNothing);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      },
    );
  });
}
