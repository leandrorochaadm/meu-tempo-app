import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  late bool doneTapped;
  late bool editTapped;
  late bool deleteTapped;

  setUp(() {
    doneTapped = false;
    editTapped = false;
    deleteTapped = false;
  });

  Widget harness(TaskNode node) => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: TaskNodeTile(
            node: node,
            isActive: false,
            onAddSubtask: (_) {},
            onToggleTimer: (_, _) {},
            onAddTime: (_, _) {},
            onToggleDone: (_, _) => doneTapped = true,
            onDelete: (_) => deleteTapped = true,
            onEdit: (_) => editTapped = true,
            onMove: (_) {},
          ),
        ),
      );

  testWidgets('folha: arrastar para a direita conclui', (tester) async {
    await tester.pumpWidget(harness(leafNode()));

    await tester.drag(find.text('Folha'), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(doneTapped, isTrue);
  });

  testWidgets('mãe: arrastar para a direita NÃO conclui (gate isLeaf)',
      (tester) async {
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
    final container = tester.widgetList<Container>(find.byType(Container)).firstWhere(
      (c) {
        final d = c.decoration;
        return d is BoxDecoration && d.border is Border;
      },
    );
    final border = (container.decoration! as BoxDecoration).border! as Border;
    return border.left.color;
  }

  testWidgets('folha atrasada pinta a borda esquerda de warning',
      (tester) async {
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

      expect(find.text('gasto 30min · est. 1h · #3'), findsOneWidget);
    });

    testWidgets('folha sem posição não exibe #', (tester) async {
      await tester.pumpWidget(harness(leafNode()));

      expect(find.text('gasto 30min · est. 1h'), findsOneWidget);
      expect(find.textContaining('#'), findsNothing);
    });

    testWidgets('mãe não exibe # (não entra na fila)', (tester) async {
      await tester.pumpWidget(harness(parentNode()));

      expect(find.textContaining('#'), findsNothing);
    });
  });

  group('mãe cuja filha foi removida pelo filtro de lista', () {
    testWidgets('não conclui por swipe (continua não sendo folha)',
        (tester) async {
      await tester.pumpWidget(harness(parentWithFilteredChild()));

      await tester.drag(find.text('Mãe'), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(doneTapped, isFalse);
    });

    testWidgets('não oferece cronômetro nem registro de tempo', (tester) async {
      await tester.pumpWidget(harness(parentWithFilteredChild()));

      // Ações de tempo existem só na folha (gate `node.isLeaf` no tile).
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      expect(find.text('+15'), findsNothing);
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
}
