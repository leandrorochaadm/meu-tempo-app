import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/usecases/get_active_task_details_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/get_prioritized_leaves_use_case.dart';

void main() {
  const useCase =
      GetActiveTaskDetailsUseCase(GetPrioritizedLeavesUseCase());
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
    bool isDone = false,
    bool hasChildren = false,
  }) =>
      TaskEntity(
        id: 't1',
        title: 'Fazer telas',
        listId: listId,
        createdAt: DateTime(2026, 7, 20),
        estimatedMinutes: estimatedMinutes,
        dueDate: dueDate,
        importance: importance,
        isDone: isDone,
        hasChildren: hasChildren,
      );

  /// Outra folha qualquer, para compor a fila de prioridade.
  TaskEntity other(String id, {required int minutes, required int dueInDays}) =>
      TaskEntity(
        id: id,
        title: id,
        listId: 'work',
        createdAt: DateTime(2026, 7, 20),
        estimatedMinutes: minutes,
        dueDate: today.add(Duration(days: dueInDays)),
        importance: ImportanceEnum.max,
      );

  test('resolve nome e posição da lista da tarefa', () {
    final task = leaf();
    final details = useCase(task, lists, [task], today);

    expect(details.listName, 'Trabalho');
    expect(details.listColorIndex, 1);
  });

  test('lista inexistente devolve nome vazio e índice neutro', () {
    final task = leaf(listId: 'sumiu');
    final details = useCase(task, lists, [task], today);

    expect(details.listName, '');
    expect(details.listColorIndex, 0);
  });

  test('prioridade segue tempoEstimado × (5 − importância) × urgência', () {
    // 60 min × (5 − 1) × urgência do prazo de hoje.
    final task = leaf(dueDate: today);
    final details = useCase(task, lists, [task], today);

    expect(details.priority, greaterThan(0));
    expect(details.priority % (60 * 4), 0);
  });

  test('sem estimativa a prioridade é zero', () {
    final task = leaf(estimatedMinutes: null);
    final details = useCase(task, lists, [task], today);

    expect(details.priority, 0);
  });

  test('marca atraso quando o prazo é anterior a hoje', () {
    final task = leaf(dueDate: today.subtract(const Duration(days: 1)));
    final details = useCase(task, lists, [task], today);

    expect(details.isOverdue, isTrue);
  });

  test('prazo de hoje não é atraso', () {
    final task = leaf(dueDate: today);
    final details = useCase(task, lists, [task], today);

    expect(details.isOverdue, isFalse);
  });

  group('rank — posição na fila de prioridade', () {
    test('tarefa sozinha na fila é #1', () {
      final task = leaf(dueDate: today);
      final details = useCase(task, lists, [task], today);

      expect(details.rank, 1);
    });

    test('reflete a posição entre as outras folhas', () {
      // 't1': 60 × 4 × 6 = 1440 (vence hoje). 'grande': 600 × 4 × 6 = 14400.
      final task = leaf(dueDate: today);
      final all = [
        task,
        other('grande', minutes: 600, dueInDays: 0),
        other('pequena', minutes: 10, dueInDays: 0),
      ];

      final details = useCase(task, lists, all, today);

      expect(details.rank, 2); // atrás de 'grande', à frente de 'pequena'
    });

    test('sobe de posição quando o atraso aumenta', () {
      final atrasada = leaf(dueDate: today.subtract(const Duration(days: 30)));
      final all = [atrasada, other('grande', minutes: 600, dueInDays: 0)];

      // 60 × 4 × 36 = 8640 — ainda atrás de 'grande' (14400).
      expect(useCase(atrasada, lists, all, today).rank, 2);

      // Com 'grande' menor, a atrasada assume a frente.
      final all2 = [atrasada, other('grande', minutes: 30, dueInDays: 0)];
      expect(useCase(atrasada, lists, all2, today).rank, 1);
    });

    test('tarefa concluída não tem posição na fila', () {
      final task = leaf(dueDate: today, isDone: true);
      final details = useCase(task, lists, [task], today);

      expect(details.rank, isNull);
    });

    test('tarefa que virou mãe não tem posição na fila', () {
      final task = leaf(dueDate: today, hasChildren: true);
      final details = useCase(task, lists, [task], today);

      expect(details.rank, isNull);
    });

    test('lista vazia (tarefa fora da coleção) não tem posição', () {
      final details = useCase(leaf(dueDate: today), lists, const [], today);

      expect(details.rank, isNull);
    });
  });
}
