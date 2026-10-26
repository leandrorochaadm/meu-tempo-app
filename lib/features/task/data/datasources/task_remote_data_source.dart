import 'package:injectable/injectable.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../../core/constants/pb_schema.dart';
import '../../../../core/data/pocketbase/pocketbase_session.dart';
import '../../../../core/data/pocketbase/record_watcher.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/pocketbase_error_mapper.dart';
import '../../../../core/utils/record_id_generator.dart';
import '../models/task_model.dart';
import '../task_batch_order.dart';

abstract class TaskRemoteDataSource {
  /// Fluxo das tarefas. `includeDone == false` filtra as concluídas já na query
  /// (menos leitura/banda no caso comum) — usa o índice
  /// `(user, is_done, created_at)`.
  Stream<List<TaskModel>> watchTasks({required bool includeDone});
  Future<TaskModel> create(TaskModel task);

  /// Cria a filha **e** marca o pai como não-folha num único `batch` —
  /// nunca deixa o pai com `hasChildren` desatualizado.
  Future<TaskModel> createChild(TaskModel child, {required String parentId});

  /// Grava a **subárvore movida** (a tarefa e seus descendentes, que herdam a
  /// lista do novo pai) e ajusta o `hasChildren` dos pais envolvidos no mesmo
  /// `batch`. [newParentId] recebe `true`; [emptiedParentId] (pai antigo
  /// que ficou sem filhas) recebe `false`.
  Future<void> moveTask(
    List<TaskModel> subtree, {
    String? newParentId,
    String? emptiedParentId,
  });

  /// Grava várias tarefas num único `batch` — usado quando editar uma
  /// tarefa mãe precisa propagar a lista para as filhas/netas.
  Future<void> updateAll(List<TaskModel> tasks);

  /// Remove a subárvore inteira e, no mesmo `batch`, marca
  /// [emptiedParentId] como folha quando o pai ficou sem filhas.
  Future<void> deleteSubtree(List<String> taskIds, {String? emptiedParentId});

  /// Recria a subárvore (ids originais) e remarca [parentId] como não-folha no
  /// mesmo `batch` — desfazer de uma exclusão em cascata.
  Future<void> restoreSubtree(List<TaskModel> tasks, {String? parentId});
  Future<void> addSpentMinutes(String taskId, int delta);
  Future<List<TaskModel>> getTasks();
  Future<void> setDone(String taskId, bool value);
  Future<void> update(TaskModel task);
  Future<void> delete(String taskId);
}

@LazySingleton(as: TaskRemoteDataSource)
class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  TaskRemoteDataSourceImpl(this._session, this._watcher);

  final PocketBaseSession _session;
  final RecordWatcher _watcher;

  RecordService get _records => _session.client.collection(PbCollections.tasks);

  Future<List<TaskModel>> _fetch({String? filter}) async {
    final records = await _records.getFullList(
      filter: filter,
      sort: '-${PbFields.createdAt}',
    );
    return records.map(TaskModel.fromRecord).toList();
  }

  BatchService _newBatch() => _session.client.createBatch();

  void _markParent(BatchService batch, String parentId, bool value) {
    batch
        .collection(PbCollections.tasks)
        .update(parentId, body: {PbFields.hasChildren: value});
  }

  Future<void> _send(BatchService batch) async {
    try {
      await batch.send();
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  @override
  Stream<List<TaskModel>> watchTasks({required bool includeDone}) {
    _session.userId;
    final filter = includeDone
        ? null
        : _session.client.filter('${PbFields.isDone} = {:done}', {
            'done': false,
          });
    return _watcher.watch(
      collection: PbCollections.tasks,
      load: () => _fetch(filter: filter),
    );
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
  Future<TaskModel> createChild(
    TaskModel child, {
    required String parentId,
  }) async {
    final userId = _session.userId;
    final id = RecordIdGenerator.next();
    final batch = _newBatch();
    batch
        .collection(PbCollections.tasks)
        .create(
          body: {...child.toJson(), PbFields.id: id, PbFields.user: userId},
        );
    _markParent(batch, parentId, true);
    await _send(batch);
    try {
      return TaskModel.fromRecord(await _records.getOne(id));
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  @override
  Future<void> updateAll(List<TaskModel> tasks) async {
    _session.userId;
    if (tasks.isEmpty) return;
    final batch = _newBatch();
    for (final task in tasks) {
      batch
          .collection(PbCollections.tasks)
          .update(task.id, body: task.toJson());
    }
    await _send(batch);
  }

  @override
  Future<void> moveTask(
    List<TaskModel> subtree, {
    String? newParentId,
    String? emptiedParentId,
  }) async {
    _session.userId;
    if (subtree.isEmpty && newParentId == null && emptiedParentId == null) {
      return;
    }
    final batch = _newBatch();
    for (final task in subtree) {
      batch
          .collection(PbCollections.tasks)
          .update(task.id, body: task.toJson());
    }
    if (newParentId != null) _markParent(batch, newParentId, true);
    if (emptiedParentId != null) _markParent(batch, emptiedParentId, false);
    await _send(batch);
  }

  @override
  Future<void> deleteSubtree(
    List<String> taskIds, {
    String? emptiedParentId,
  }) async {
    _session.userId;
    if (taskIds.isEmpty && emptiedParentId == null) return;
    final batch = _newBatch();
    for (final id in taskIds.reversed) {
      batch.collection(PbCollections.tasks).delete(id);
    }
    if (emptiedParentId != null) _markParent(batch, emptiedParentId, false);
    await _send(batch);
  }

  @override
  Future<void> restoreSubtree(List<TaskModel> tasks, {String? parentId}) async {
    final userId = _session.userId;
    if (tasks.isEmpty && parentId == null) return;
    final ordered = orderParentsFirst(tasks);
    final batch = _newBatch();
    for (final task in ordered) {
      batch
          .collection(PbCollections.tasks)
          .create(
            body: {
              ...task.toJson(),
              PbFields.id: task.id,
              PbFields.user: userId,
            },
          );
    }
    if (parentId != null) _markParent(batch, parentId, true);
    try {
      await _send(batch);
    } on ConflictException {
      // Undo tapped twice: the tasks still exist, so overwrite them.
      final retry = _newBatch();
      for (final task in ordered) {
        retry
            .collection(PbCollections.tasks)
            .update(task.id, body: task.toJson());
      }
      if (parentId != null) _markParent(retry, parentId, true);
      await _send(retry);
    }
  }

  @override
  Future<void> addSpentMinutes(String taskId, int delta) async {
    _session.userId;
    try {
      await _records.update(
        taskId,
        body: {PbFields.increment(PbFields.spentMinutes): delta},
      );
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  @override
  Future<List<TaskModel>> getTasks() async {
    _session.userId;
    try {
      return await _fetch();
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  @override
  Future<void> setDone(String taskId, bool value) async {
    _session.userId;
    try {
      await _records.update(taskId, body: {PbFields.isDone: value});
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  @override
  Future<void> update(TaskModel task) async {
    _session.userId;
    try {
      await _records.update(task.id, body: task.toJson());
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  @override
  Future<void> delete(String taskId) async {
    _session.userId;
    try {
      await _records.delete(taskId);
    } on ClientException catch (e) {
      final error = mapPocketBaseError(e);
      if (error is NotFoundException) return;
      throw error;
    }
  }
}
