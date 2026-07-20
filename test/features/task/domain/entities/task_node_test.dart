import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/task_node.dart';

void main() {
  final today = DateTime(2026, 7, 20);

  TaskEntity leaf(String id, {int minutes = 30, bool done = false}) =>
      TaskEntity(
        id: id,
        title: id,
        listId: 'inbox',
        createdAt: today,
        estimatedMinutes: minutes,
        isDone: done,
      );

  test('folha: tempo é o próprio, progresso reflete conclusão', () {
    final node = TaskNode(task: leaf('a', minutes: 45), level: 2);
    expect(node.isLeaf, isTrue);
    expect(node.totalEstimatedMinutes, 45);
    expect(node.leafCount, 1);
    expect(node.progress, 0);
  });

  test('mãe: tempo e progresso derivam das folhas', () {
    final mae = TaskNode(
      task: leaf('mae'),
      level: 0,
      children: [
        TaskNode(task: leaf('f1', minutes: 60, done: true), level: 1),
        TaskNode(task: leaf('f2', minutes: 30), level: 1),
      ],
    );

    expect(mae.isLeaf, isFalse);
    expect(mae.totalEstimatedMinutes, 90); // 60 + 30
    expect(mae.leafCount, 2);
    expect(mae.doneLeafCount, 1);
    expect(mae.progress, 0.5);
  });

  test('isMaxLevel só é true no nível de neta (2)', () {
    expect(TaskNode(task: leaf('a'), level: 1).isMaxLevel, isFalse);
    expect(TaskNode(task: leaf('a'), level: 2).isMaxLevel, isTrue);
  });
}
