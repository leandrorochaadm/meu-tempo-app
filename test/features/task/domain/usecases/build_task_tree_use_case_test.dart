import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/usecases/build_task_tree_use_case.dart';

void main() {
  final today = DateTime(2026, 7, 20);
  const useCase = BuildTaskTreeUseCase();

  TaskEntity t(String id, {String? parentId}) => TaskEntity(
        id: id,
        title: id,
        listId: 'inbox',
        createdAt: today,
        parentId: parentId,
        estimatedMinutes: 30,
      );

  test('monta mãe → filha → neta com níveis corretos', () {
    final roots = useCase([
      t('mae'),
      t('filha', parentId: 'mae'),
      t('neta', parentId: 'filha'),
    ]);

    expect(roots.length, 1);
    final mae = roots.single;
    expect(mae.level, 0);
    expect(mae.children.single.level, 1);
    expect(mae.children.single.children.single.level, 2);
    expect(mae.children.single.children.single.task.id, 'neta');
  });

  test('múltiplas raízes e folhas soltas', () {
    final roots = useCase([t('a'), t('b')]);
    expect(roots.map((n) => n.task.id), containsAll(['a', 'b']));
    expect(roots.every((n) => n.isLeaf), isTrue);
  });
}
