import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/usecases/get_active_task_details_use_case.dart';

void main() {
  const useCase = GetActiveTaskDetailsUseCase();
  final today = DateTime(2026, 7, 25);

  const lists = [
    TaskListEntity(id: 'inbox', name: 'Entrada', isDefault: true),
    TaskListEntity(id: 'work', name: 'Trabalho'),
  ];

  TaskEntity leaf({
    String listId = 'work',
    int? estimatedMinutes = 60,
    DateTime? dueDate,
    ImportanceEnum? importance = ImportanceEnum.max,
  }) =>
      TaskEntity(
        id: 't1',
        title: 'Fazer telas',
        listId: listId,
        createdAt: DateTime(2026, 7, 20),
        estimatedMinutes: estimatedMinutes,
        dueDate: dueDate,
        importance: importance,
      );

  test('resolve nome e posição da lista da tarefa', () {
    final details = useCase(leaf(), lists, today);

    expect(details.listName, 'Trabalho');
    expect(details.listColorIndex, 1);
  });

  test('lista inexistente devolve nome vazio e índice neutro', () {
    final details = useCase(leaf(listId: 'sumiu'), lists, today);

    expect(details.listName, '');
    expect(details.listColorIndex, 0);
  });

  test('prioridade segue tempoEstimado × (5 − importância) × urgência', () {
    // 60 min × (5 − 1) × urgência do prazo de hoje.
    final details = useCase(leaf(dueDate: today), lists, today);

    expect(details.priority, greaterThan(0));
    expect(details.priority % (60 * 4), 0);
  });

  test('sem estimativa a prioridade é zero', () {
    final details = useCase(leaf(estimatedMinutes: null), lists, today);

    expect(details.priority, 0);
  });

  test('marca atraso quando o prazo é anterior a hoje', () {
    final details = useCase(
      leaf(dueDate: today.subtract(const Duration(days: 1))),
      lists,
      today,
    );

    expect(details.isOverdue, isTrue);
  });

  test('prazo de hoje não é atraso', () {
    final details = useCase(leaf(dueDate: today), lists, today);

    expect(details.isOverdue, isFalse);
  });
}
