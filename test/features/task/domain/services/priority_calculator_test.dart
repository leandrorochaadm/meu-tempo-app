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

  // 60 min × (5 − 1) = 240 é o fator fixo; o que varia é a urgência.
  const factor = 240;

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
}
