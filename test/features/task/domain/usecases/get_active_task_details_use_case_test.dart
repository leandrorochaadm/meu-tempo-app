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

  test('prioridade segue faixaDeEsforço × (5 − importância) × urgência', () {
    // 60 min = faixa média (3) × (5 − 1) × urgência 6 (vence hoje).
    final task = leaf(dueDate: today);
    final details = useCase(task, lists, [task], today);

    expect(details.priority, 3 * 4 * 6);
  });

  test('sem estimativa cai na faixa de esforço mais rápida', () {
    // Faixa rápida (1) × (5 − 1) × sem prazo (1) — não zera mais a prioridade.
    final task = leaf(estimatedMinutes: null);
    final details = useCase(task, lists, [task], today);

    expect(details.priority, 1 * 4 * 1);
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
      // 't1': média (3) × 4 × 6 = 72. 'grande': muito longa (5) × 4 × 6 = 120.
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
      // No prazo, a folha longa vem na frente: 5 × 4 × 6 = 120 contra 3 × 4 × 6 = 72.
      final noPrazo = leaf(dueDate: today);
      final all = [noPrazo, other('grande', minutes: 600, dueInDays: 0)];
      expect(useCase(noPrazo, lists, all, today).rank, 2);

      // Com 30 dias de atraso a urgência vai a 36 e ela assume a frente (432).
      final atrasada = leaf(dueDate: today.subtract(const Duration(days: 30)));
      final all2 = [atrasada, other('grande', minutes: 600, dueInDays: 0)];
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
