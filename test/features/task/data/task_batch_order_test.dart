import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/data/models/task_model.dart';
import 'package:meu_tempo/features/task/data/task_batch_order.dart';

TaskModel _t(String id, {String? parentId}) => TaskModel.raw(
  id: id,
  title: id,
  listId: 'l1',
  createdAt: null,
  parentId: parentId,
);

void main() {
  test('places parents before children in a three level tree', () {
    final result = orderParentsFirst([
      _t('neta1', parentId: 'filha1'),
      _t('filha2', parentId: 'mae'),
      _t('mae', parentId: 'externa'),
      _t('neta2', parentId: 'filha2'),
      _t('filha1', parentId: 'mae'),
    ]).map((t) => t.id).toList();

    expect(result.toSet(), {'neta1', 'filha2', 'mae', 'neta2', 'filha1'});
    expect(result, hasLength(5));
    expect(result.indexOf('mae'), lessThan(result.indexOf('filha1')));
    expect(result.indexOf('mae'), lessThan(result.indexOf('filha2')));
    expect(result.indexOf('filha1'), lessThan(result.indexOf('neta1')));
    expect(result.indexOf('filha2'), lessThan(result.indexOf('neta2')));
  });

  test('keeps the received order of independent roots', () {
    final result = orderParentsFirst([_t('b'), _t('a')]).map((t) => t.id);
    expect(result, ['b', 'a']);
  });

  test('handles empty and single lists', () {
    expect(orderParentsFirst([]), isEmpty);
    expect(orderParentsFirst([_t('a')]).single.id, 'a');
  });

  test('does not hang on a cycle', () {
    final result = orderParentsFirst([
      _t('a', parentId: 'b'),
      _t('b', parentId: 'a'),
    ]);
    expect(result.map((t) => t.id), ['a', 'b']);
  });
}
