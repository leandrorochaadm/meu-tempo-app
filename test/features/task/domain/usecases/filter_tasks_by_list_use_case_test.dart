import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/usecases/filter_tasks_by_list_use_case.dart';

void main() {
  const useCase = FilterTasksByListUseCase();
  final createdAt = DateTime(2026, 7, 20);

  TaskEntity task(String id, String listId, {String? parentId}) => TaskEntity(
        id: id,
        title: id,
        listId: listId,
        createdAt: createdAt,
        parentId: parentId,
      );

  // Hierarquia: mãe(A) → filha(A) → neta(B), + solta(B).
  final mae = task('mae', 'A');
  final filha = task('filha', 'A', parentId: 'mae');
  final neta = task('neta', 'B', parentId: 'filha');
  final solta = task('solta', 'B');
  final tasks = [mae, filha, neta, solta];

  test('listId null retorna a lista inalterada (todas as listas)', () {
    expect(useCase(tasks, null), tasks);
  });

  test('filtra pela lista mantendo só as tarefas da lista e seus ancestrais',
      () {
    // Lista B: a neta (B) e a solta (B) entram; a mãe e a filha entram como
    // ancestrais da neta (mesmo sendo da lista A). Nada mais.
    final result = useCase(tasks, 'B');
    expect(
      result.map((t) => t.id).toSet(),
      {'neta', 'solta', 'mae', 'filha'},
    );
  });

  test('lista A não puxa a neta (que é de B) — sem descendentes de outra lista',
      () {
    final result = useCase(tasks, 'A');
    expect(result.map((t) => t.id).toSet(), {'mae', 'filha'});
  });

  test('lista sem nenhuma tarefa retorna vazio', () {
    expect(useCase(tasks, 'inexistente'), isEmpty);
  });
}
