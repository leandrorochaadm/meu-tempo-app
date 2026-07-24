import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/services/overdue_evaluator.dart';

void main() {
  final today = DateTime(2026, 7, 21);

  TaskEntity leaf({
    DateTime? dueDate,
    bool isDone = false,
    bool hasChildren = false,
  }) =>
      TaskEntity(
        id: 't1',
        title: 'Tarefa',
        listId: 'l1',
        createdAt: today,
        dueDate: dueDate,
        isDone: isDone,
        hasChildren: hasChildren,
        estimatedMinutes: 30,
      );

  test('atrasada: folha não concluída com prazo antes de hoje', () {
    final task = leaf(dueDate: DateTime(2026, 7, 20));
    expect(OverdueEvaluator.isOverdue(task, today), isTrue);
  });

  test('não atrasada: prazo é hoje (só antes de hoje conta)', () {
    final task = leaf(dueDate: DateTime(2026, 7, 21, 23, 59));
    expect(OverdueEvaluator.isOverdue(task, today), isFalse);
  });

  test('não atrasada: prazo no futuro', () {
    final task = leaf(dueDate: DateTime(2026, 7, 22));
    expect(OverdueEvaluator.isOverdue(task, today), isFalse);
  });

  test('não atrasada: concluída mesmo com prazo vencido', () {
    final task = leaf(dueDate: DateTime(2026, 7, 10), isDone: true);
    expect(OverdueEvaluator.isOverdue(task, today), isFalse);
  });

  test('não atrasada: mãe/avó (tem filhas) nunca é atrasada', () {
    final task = leaf(dueDate: DateTime(2026, 7, 10), hasChildren: true);
    expect(OverdueEvaluator.isOverdue(task, today), isFalse);
  });

  test('não atrasada: sem prazo definido', () {
    expect(OverdueEvaluator.isOverdue(leaf(), today), isFalse);
  });
}
