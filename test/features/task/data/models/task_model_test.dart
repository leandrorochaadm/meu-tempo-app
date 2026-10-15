import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/data/models/task_model.dart';
import 'package:meu_tempo/features/task/data/task_fields.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';

void main() {
  final createdAt = DateTime(2026, 10, 15, 8);

  Map<String, dynamic> rawDoc({String? recurringTaskId}) => {
    'title': 'Regar plantas',
    TaskFields.listId: 'l1',
    TaskFields.createdAt: Timestamp.fromDate(createdAt),
    TaskFields.recurringTaskId: ?recurringTaskId,
  };

  TaskEntity entity({String? recurringTaskId}) => TaskEntity(
    id: 't1',
    title: 'Regar plantas',
    listId: 'l1',
    createdAt: createdAt,
    recurringTaskId: recurringTaskId,
  );

  group('TaskModel.recurringTaskId', () {
    test('lê o vínculo do documento', () {
      final task = TaskModel.fromDoc(
        't1',
        rawDoc(recurringTaskId: 'r1'),
      ).toEntity();
      expect(task.recurringTaskId, 'r1');
    });

    test('grava o vínculo a partir da entity', () {
      final json = TaskModel.fromEntity(entity(recurringTaskId: 'r1')).toJson();
      expect(json[TaskFields.recurringTaskId], 'r1');
    });

    test('tarefa comum não grava a chave', () {
      final json = TaskModel.fromEntity(entity()).toJson();
      expect(json.containsKey(TaskFields.recurringTaskId), isFalse);
    });

    test('documento antigo sem a chave lê null', () {
      expect(
        TaskModel.fromDoc('t1', rawDoc()).toEntity().recurringTaskId,
        isNull,
      );
    });
  });
}
