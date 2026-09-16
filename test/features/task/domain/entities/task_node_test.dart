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

  /// Tarefa que tem filhas — como o banco a grava (`hasChildren: true`, mantido
  /// atomicamente ao criar/mover/excluir subtarefa).
  TaskEntity parent(String id) => TaskEntity(
        id: id,
        title: id,
        listId: 'inbox',
        createdAt: today,
        hasChildren: true,
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
      task: parent('mae'),
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

  test('isLeaf vem da tarefa, não da árvore projetada', () {
    // Mãe cuja filha foi removida pela projeção (filtro por lista): chega sem
    // `children`, mas continua não sendo folha.
    final semFilhasVisiveis = TaskNode(task: parent('mae'), level: 0);

    expect(semFilhasVisiveis.children, isEmpty);
    expect(semFilhasVisiveis.isLeaf, isFalse);
  });

  test('folha real é folha mesmo sem children', () {
    expect(TaskNode(task: leaf('a'), level: 2).isLeaf, isTrue);
  });

  test('tempo real: folha usa o próprio, mãe/avó somam as folhas', () {
    final f1 = TaskEntity(
      id: 'f1',
      title: 'f1',
      listId: 'inbox',
      createdAt: today,
      spentMinutes: 25,
    );
    final f2 = TaskEntity(
      id: 'f2',
      title: 'f2',
      listId: 'inbox',
      createdAt: today,
      spentMinutes: 10,
    );

    expect(TaskNode(task: f1, level: 2).totalSpentMinutes, 25);

    // Avó → filha → netas: a soma atravessa os níveis.
    final avo = TaskNode(
      task: parent('avo'),
      level: 0,
      children: [
        TaskNode(
          task: parent('filha'),
          level: 1,
          children: [
            TaskNode(task: f1, level: 2),
            TaskNode(task: f2, level: 2),
          ],
        ),
      ],
    );

    expect(avo.totalSpentMinutes, 35);
    expect(avo.totalEstimatedMinutes, 0); // folhas sem estimativa → 0
    expect(avo.leafCount, 2);
    expect(avo.doneLeafCount, 0);
  });

  test('mãe sem folhas visíveis: progresso 0 sem divisão por zero', () {
    final vazia = TaskNode(task: parent('mae'), level: 0);

    expect(vazia.leafCount, 0);
    expect(vazia.progress, 0);
  });

  test('compara por valor (Equatable), inclusive rank e isOverdue', () {
    final base = TaskNode(task: leaf('a'), level: 1, rank: 1);

    expect(base, equals(TaskNode(task: leaf('a'), level: 1, rank: 1)));
    expect(base, isNot(equals(TaskNode(task: leaf('a'), level: 1, rank: 2))));
    expect(
      base,
      isNot(equals(
        TaskNode(task: leaf('a'), level: 1, rank: 1, isOverdue: true),
      )),
    );
    expect(base.props, hasLength(5));
  });
}
