import 'package:injectable/injectable.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../../core/constants/pb_schema.dart';
import '../../../../core/data/pocketbase/pocketbase_session.dart';
import '../../../../core/data/pocketbase/record_watcher.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/pocketbase_error_mapper.dart';
import '../models/task_list_model.dart';

abstract class TaskListRemoteDataSource {
  Stream<List<TaskListModel>> watchLists();
  Future<List<TaskListModel>> getLists();
  Future<TaskListModel> create(TaskListModel list);
  Future<void> rename(String listId, String name);
  Future<void> delete(String listId);
}

@LazySingleton(as: TaskListRemoteDataSource)
class TaskListRemoteDataSourceImpl implements TaskListRemoteDataSource {
  TaskListRemoteDataSourceImpl(this._session, this._watcher);

  final PocketBaseSession _session;
  final RecordWatcher _watcher;

  RecordService get _records =>
      _session.client.collection(PbCollections.taskLists);

  @override
  Stream<List<TaskListModel>> watchLists() {
    _session.userId;
    return _watcher.watch(
      collection: PbCollections.taskLists,
      load: _fetchLists,
    );
  }

  @override
  Future<List<TaskListModel>> getLists() async {
    _session.userId;
    return _fetchLists();
  }

  Future<List<TaskListModel>> _fetchLists() async {
    try {
      final records = await _records.getFullList(sort: PbFields.name);
      return records.map(TaskListModel.fromRecord).toList();
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  @override
  Future<TaskListModel> create(TaskListModel list) async {
    final userId = _session.userId;
    try {
      final record = await _records.create(
        body: {...list.toJson(), PbFields.user: userId},
      );
      return TaskListModel.fromRecord(record);
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  @override
  Future<void> rename(String listId, String name) async {
    _session.userId;
    try {
      await _records.update(listId, body: {PbFields.name: name});
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  @override
  Future<void> delete(String listId) async {
    _session.userId;
    try {
      await _records.delete(listId);
    } on ClientException catch (e) {
      final error = mapPocketBaseError(e);
      if (error is NotFoundException) return;
      throw error;
    }
  }
}
