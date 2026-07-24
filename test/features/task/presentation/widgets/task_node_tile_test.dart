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

  // Mãe = nó com uma filha (não é folha → sem conclusão).
  TaskNode parentNode() => TaskNode(
        task: task('parent', 'Mãe'),
        level: 0,
        children: [TaskNode(task: task('child', 'Filha'), level: 1)],
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
}
