import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/constants/pb_schema.dart';
import 'package:meu_tempo/features/list/data/models/task_list_model.dart';
import 'package:pocketbase/pocketbase.dart';

void main() {
  RecordModel record(Map<String, dynamic> extra) => RecordModel.fromJson({
    'id': 'abc123def456ghi',
    'collectionId': 'pbc_1',
    'collectionName': 'task_lists',
    'user': 'user-a',
    'name': 'Entrada',
    ...extra,
  });

  test('fromRecord maps the PocketBase payload', () {
    final entity = TaskListModel.fromRecord(
      record({'is_default': true}),
    ).toEntity();
    expect(entity.id, 'abc123def456ghi');
    expect(entity.name, 'Entrada');
    expect(entity.isDefault, isTrue);
  });

  test('missing is_default is false', () {
    expect(TaskListModel.fromRecord(record({})).isDefault, isFalse);
  });

  test('toJson has only name and is_default', () {
    final json = TaskListModel.fromRecord(record({})).toJson();
    expect(json.keys.toSet(), {PbFields.name, PbFields.isDefault});
  });
}
