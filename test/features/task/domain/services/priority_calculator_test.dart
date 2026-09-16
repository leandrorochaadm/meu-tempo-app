import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/services/priority_calculator.dart';

void main() {
  final today = DateTime(2026, 7, 25);

  TaskEntity leaf({DateTime? dueDate, ImportanceEnum? importance}) => TaskEntity(
        id: 't1',
        title: 'Tarefa',
        listId: 'l1',
        createdAt: today,
        dueDate: dueDate,
        estimatedMinutes: 60,
        importance: importance ?? ImportanceEnum.max,
      );

  int priorityForDueIn(int days) =>
      PriorityCalculator.of(leaf(dueDate: today.add(Duration(days: days))), today);

  // 60 min = faixa média (peso 3) × (5 − 1) = 12 é o fator fixo; varia a urgência.
  const factor = 12;

  test('vence hoje usa urgência 6', () {
    expect(priorityForDueIn(0), factor * 6);
  });

  test('atraso soma 1 por dia atrasado, sem teto', () {
    expect(priorityForDueIn(-1), factor * 7);
    expect(priorityForDueIn(-5), factor * 11);
    expect(priorityForDueIn(-30), factor * 36);
  });

  test('quanto mais atrasada, maior a prioridade', () {
    expect(priorityForDueIn(-10), greaterThan(priorityForDueIn(-3)));
    expect(priorityForDueIn(-3), greaterThan(priorityForDueIn(0)));
  });

  test('faixas de prazo futuro seguem inalteradas', () {
    expect(priorityForDueIn(2), factor * 5);
    expect(priorityForDueIn(5), factor * 4);
    expect(priorityForDueIn(9), factor * 3);
    expect(priorityForDueIn(14), factor * 2);
    expect(priorityForDueIn(15), factor * 1);
  });

  test('sem prazo cai na faixa mais fraca', () {
    expect(PriorityCalculator.of(leaf(), today), factor * 1);
  });

  group('faixa de esforço', () {
    TaskEntity leafOf(int minutes) => TaskEntity(
          id: 't1',
          title: 'Tarefa',
          listId: 'l1',
          createdAt: today,
          dueDate: today,
          estimatedMinutes: minutes,
          importance: ImportanceEnum.max,
        );

    test('o tempo entra pelo peso da faixa, não em minutos crus', () {
      // (5−1) × urgência 6 = 24 é o fator fixo; varia só o peso da faixa.
      expect(PriorityCalculator.of(leafOf(15), today), 24 * 1);
      expect(PriorityCalculator.of(leafOf(30), today), 24 * 2);
      expect(PriorityCalculator.of(leafOf(60), today), 24 * 3);
      expect(PriorityCalculator.of(leafOf(180), today), 24 * 4);
      expect(PriorityCalculator.of(leafOf(480), today), 24 * 5);
    });

    test('estimativas na mesma faixa pontuam igual', () {
      expect(
        PriorityCalculator.of(leafOf(20), today),
        PriorityCalculator.of(leafOf(30), today),
      );
    });

    test('importância e prazo ganham de uma tarefa longa e irrelevante', () {
      final longa = TaskEntity(
        id: 'longa',
        title: 'Longa',
        listId: 'l1',
        createdAt: today,
        estimatedMinutes: 480,
        importance: ImportanceEnum.min,
      );
      final curtaUrgente = leafOf(15);

      expect(
        PriorityCalculator.of(curtaUrgente, today),
        greaterThan(PriorityCalculator.of(longa, today)),
      );
    });
  });
}
