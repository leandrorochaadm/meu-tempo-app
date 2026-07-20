import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/usecases/get_prioritized_leaves_use_case.dart';

void main() {
  const useCase = GetPrioritizedLeavesUseCase();
  final today = DateTime(2026, 7, 20);

  TaskEntity leaf(
    String id, {
    required int minutes,
    required ImportanceEnum importance,
    required int dueInDays,
    String? parentId,
    bool done = false,
    bool hasChildren = false,
  }) =>
      TaskEntity(
        id: id,
        title: id,
        listId: 'inbox',
        createdAt: today,
        parentId: parentId,
        estimatedMinutes: minutes,
        importance: importance,
        dueDate: today.add(Duration(days: dueInDays)),
        isDone: done,
        hasChildren: hasChildren,
      );

  test('exemplo do requisito: 2h/imp1/hoje (48) acima de 2h/imp1/+4d (32)', () {
    final result = useCase([
      leaf('hoje',
          minutes: 120, importance: ImportanceEnum.max, dueInDays: 0),
      leaf('depois',
          minutes: 120, importance: ImportanceEnum.max, dueInDays: 4),
    ], today);

    expect(result.first.task.id, 'hoje');
    // 120 × (5−1) × 6 = 2880 ; 120 × (5−1) × 4 = 1920
    expect(result[0].priority, 2880);
    expect(result[1].priority, 1920);
  });

  test('exclui folhas concluídas e não-folhas', () {
    final result = useCase([
      leaf('done',
          minutes: 60, importance: ImportanceEnum.max, dueInDays: 0, done: true),
      leaf('mae',
          minutes: 60,
          importance: ImportanceEnum.max,
          dueInDays: 0,
          hasChildren: true),
      leaf('ok', minutes: 60, importance: ImportanceEnum.max, dueInDays: 0),
    ], today);

    expect(result.map((l) => l.task.id), ['ok']);
  });

  test('monta o subtítulo da hierarquia (mãe › filha)', () {
    final tasks = [
      TaskEntity(
          id: 'mae',
          title: 'Lançar app',
          listId: 'inbox',
          createdAt: today,
          hasChildren: true),
      TaskEntity(
          id: 'filha',
          title: 'Fazer telas',
          listId: 'inbox',
          createdAt: today,
          parentId: 'mae',
          hasChildren: true),
      leaf('neta',
          minutes: 30,
          importance: ImportanceEnum.min,
          dueInDays: 0,
          parentId: 'filha'),
    ];

    final result = useCase(tasks, today);
    expect(result.single.ancestryLabel, 'Lançar app › Fazer telas');
  });
}
