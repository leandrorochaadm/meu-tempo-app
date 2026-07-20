import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/report/domain/usecases/get_list_report_use_case.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';

void main() {
  const useCase = GetListReportUseCase();
  final today = DateTime(2026, 7, 20);

  TaskEntity leaf(String id, String listId, int est, int spent,
          {bool hasChildren = false}) =>
      TaskEntity(
        id: id,
        title: id,
        listId: listId,
        createdAt: today,
        estimatedMinutes: est,
        spentMinutes: spent,
        hasChildren: hasChildren,
      );

  test('agrega estimado × real por lista e ignora não-folhas', () {
    final rows = useCase(
      [
        leaf('a', 'prof', 60, 90),
        leaf('b', 'prof', 30, 0),
        leaf('mae', 'prof', 0, 0, hasChildren: true), // ignorada
        leaf('c', 'estudo', 120, 45),
      ],
      const [
        TaskListEntity(id: 'prof', name: 'Profissional'),
        TaskListEntity(id: 'estudo', name: 'Estudo'),
      ],
    );

    final prof = rows.firstWhere((r) => r.listId == 'prof');
    expect(prof.listName, 'Profissional');
    expect(prof.estimatedMinutes, 90); // 60 + 30
    expect(prof.spentMinutes, 90);
    final estudo = rows.firstWhere((r) => r.listId == 'estudo');
    expect(estudo.estimatedMinutes, 120);
    expect(estudo.spentMinutes, 45);
  });

  test('ordena por tempo real desc', () {
    final rows = useCase(
      [leaf('a', 'x', 10, 10), leaf('b', 'y', 10, 100)],
      const [
        TaskListEntity(id: 'x', name: 'X'),
        TaskListEntity(id: 'y', name: 'Y'),
      ],
    );
    expect(rows.first.listId, 'y');
  });
}
