import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/services/ancestry_label_builder.dart';

void main() {
  final now = DateTime(2026, 7, 20);

  TaskEntity task(String id, {String? parentId}) => TaskEntity(
        id: id,
        title: id,
        listId: 'l',
        createdAt: now,
        parentId: parentId,
      );

  test('folha raiz → rótulo vazio', () {
    final byId = {'a': task('a')};
    expect(AncestryLabelBuilder.of(byId['a']!, byId), '');
  });

  test('mãe › avó na ordem correta', () {
    final avo = task('avo');
    final mae = task('mae', parentId: 'avo');
    final folha = task('folha', parentId: 'mae');
    final byId = {'avo': avo, 'mae': mae, 'folha': folha};
    // avo(title=avo) › mae(title=mae)
    expect(AncestryLabelBuilder.of(folha, byId), 'avo › mae');
  });

  test('pai ausente interrompe a cadeia sem quebrar', () {
    final folha = task('folha', parentId: 'sumiu');
    expect(AncestryLabelBuilder.of(folha, {'folha': folha}), '');
  });
}
