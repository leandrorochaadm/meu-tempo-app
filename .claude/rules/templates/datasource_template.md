---
paths:
  - "lib/features/*/data/datasources/**"
---

# DataSource Template (PocketBase)

```dart
import 'package:injectable/injectable.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../../core/constants/pb_schema.dart';
import '../../../../core/data/pocketbase/pocketbase_session.dart';
import '../../../../core/data/pocketbase/record_watcher.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/pocketbase_error_mapper.dart';
import '../models/task_model.dart';

abstract interface class TaskRemoteDataSource {
  Stream<List<TaskModel>> watchTasks();
  Future<TaskModel> create(TaskModel task);
  Future<void> delete(String id);
}

@LazySingleton(as: TaskRemoteDataSource)
class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  TaskRemoteDataSourceImpl(this._session, this._watcher);

  final PocketBaseSession _session;
  final RecordWatcher _watcher;

  RecordService get _records => _session.client.collection(PbCollections.tasks);

  Future<List<TaskModel>> _fetch() async {
    try {
      final records = await _records.getFullList(sort: '-${PbFields.createdAt}');
      return records.map(TaskModel.fromRecord).toList();
    } on ClientException catch (e) {
      throw mapPocketBaseError(e); // -> AppException (core/error/exceptions.dart)
    }
  }

  @override
  Stream<List<TaskModel>> watchTasks() {
    _session.userId;
    return _watcher.watch(collection: PbCollections.tasks, load: _fetch);
  }

  @override
  Future<TaskModel> create(TaskModel task) async {
    final userId = _session.userId;
    try {
      final record = await _records.create(
        body: {...task.toJson(), PbFields.user: userId},
      );
      return TaskModel.fromRecord(record);
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    _session.userId;
    try {
      await _records.delete(id);
    } on ClientException catch (e) {
      final error = mapPocketBaseError(e);
      if (error is NotFoundException) return; // já apagado
      throw error;
    }
  }
}
```

## Rules
- Retorna Model (nunca `Map`).
- Recebe `PocketBaseSession`/`RecordWatcher` por injeção (nunca cria o cliente).
- `userId` lido de `_session.userId` antes de todo pedido; `create` envia `PbFields.user`,
  `update` nunca envia `user`.
- Coleções e campos por `PbCollections`/`PbFields`; isolamento garantido pelas API Rules
  (ver `pocketbase.md`).
- try/catch em toda chamada; relançar `AppException` (o RepositoryImpl vira Failure).
