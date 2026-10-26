import 'package:injectable/injectable.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../../core/constants/pb_schema.dart';
import '../../../../core/data/pocketbase/pocketbase_session.dart';
import '../../../../core/data/pocketbase/record_watcher.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/pocketbase_error_mapper.dart';
import '../../../../core/utils/calendar_date_codec.dart';
import '../models/recurring_task_model.dart';

abstract class RecurringTaskRemoteDataSource {
  Stream<List<RecurringTaskModel>> watchAll();
  Future<List<RecurringTaskModel>> getAll();
  Future<RecurringTaskModel> create(RecurringTaskModel template);

  /// Não grava `lastGeneratedOn` (posse do [claimGeneration]).
  Future<void> update(RecurringTaskModel template);
  Future<void> delete(String id);
  Future<void> restore(RecurringTaskModel template);
  Future<void> moveToList(String fromListId, String toListId);
  Future<void> deleteByList(String listId);

  /// Num único `batch` com marcador de dia em `recurring_task_claims`: lê o
  /// modelo [id]; se ele existe e [canClaim] aceita o atual, grava
  /// `lastGeneratedOn` = [day] e devolve `true`; senão não grava nada e
  /// devolve `false`. [canClaim] precisa ser puro.
  Future<bool> claimGeneration(
    String id,
    DateTime day, {
    required bool Function(RecurringTaskModel current) canClaim,
  });
}

@LazySingleton(as: RecurringTaskRemoteDataSource)
class RecurringTaskRemoteDataSourceImpl
    implements RecurringTaskRemoteDataSource {
  RecurringTaskRemoteDataSourceImpl(this._session, this._watcher);

  final PocketBaseSession _session;
  final RecordWatcher _watcher;

  RecordService get _records =>
      _session.client.collection(PbCollections.recurringTasks);

  Future<List<RecurringTaskModel>> _fetch() async {
    final records = await _records.getFullList(sort: PbFields.title);
    return records.map(RecurringTaskModel.fromRecord).toList();
  }

  Future<List<RecordModel>> _inList(String listId) => _records.getFullList(
    filter: _session.client.filter('${PbFields.list} = {:id}', {'id': listId}),
  );

  @override
  Stream<List<RecurringTaskModel>> watchAll() {
    _session.userId;
    return _watcher.watch(
      collection: PbCollections.recurringTasks,
      load: _fetch,
    );
  }

  @override
  Future<List<RecurringTaskModel>> getAll() async {
    _session.userId;
    try {
      return await _fetch();
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  @override
  Future<RecurringTaskModel> create(RecurringTaskModel template) async {
    final userId = _session.userId;
    try {
      final record = await _records.create(
        body: {...template.toJson(), PbFields.user: userId},
      );
      return RecurringTaskModel.fromRecord(record);
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  @override
  Future<void> update(RecurringTaskModel template) async {
    _session.userId;
    try {
      final body = template.toJson()..remove(PbFields.lastGeneratedOn);
      await _records.update(template.id, body: body);
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
      if (error is NotFoundException) return;
      throw error;
    }
  }

  @override
  Future<void> restore(RecurringTaskModel template) async {
    final userId = _session.userId;
    try {
      await _records.create(
        body: {
          ...template.toJson(),
          PbFields.id: template.id,
          PbFields.user: userId,
        },
      );
    } on ClientException catch (e) {
      final error = mapPocketBaseError(e);
      if (error is! ConflictException) throw error;
      // Undo tapped twice: the model still exists, so overwrite it.
      try {
        await _records.update(template.id, body: template.toJson());
      } on ClientException catch (e) {
        throw mapPocketBaseError(e);
      }
    }
  }

  @override
  Future<void> moveToList(String fromListId, String toListId) async {
    _session.userId;
    try {
      final records = await _inList(fromListId);
      if (records.isEmpty) return;
      final batch = _session.client.createBatch();
      for (final record in records) {
        batch
            .collection(PbCollections.recurringTasks)
            .update(record.id, body: {PbFields.list: toListId});
      }
      await batch.send();
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  @override
  Future<void> deleteByList(String listId) async {
    _session.userId;
    try {
      final records = await _inList(listId);
      if (records.isEmpty) return;
      final batch = _session.client.createBatch();
      for (final record in records) {
        batch.collection(PbCollections.recurringTasks).delete(record.id);
      }
      await batch.send();
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  @override
  Future<bool> claimGeneration(
    String id,
    DateTime day, {
    required bool Function(RecurringTaskModel current) canClaim,
  }) async {
    final userId = _session.userId;
    final RecurringTaskModel current;
    try {
      current = RecurringTaskModel.fromRecord(await _records.getOne(id));
    } on ClientException catch (e) {
      final error = mapPocketBaseError(e);
      if (error is NotFoundException) return false;
      throw error;
    }
    if (!canClaim(current)) return false;

    // The claim id is unique per model and day: if another device already
    // generated today, the whole batch (including the update) is rolled back.
    final dayText = CalendarDateCodec.format(day);
    final batch = _session.client.createBatch();
    batch
        .collection(PbCollections.recurringTasks)
        .update(id, body: {PbFields.lastGeneratedOn: dayText});
    batch
        .collection(PbCollections.recurringTaskClaims)
        .create(
          body: {
            PbFields.id: '$id-${dayText.substring(0, 10)}',
            PbFields.recurringTask: id,
            PbFields.user: userId,
          },
        );
    try {
      await batch.send();
      return true;
    } on ClientException catch (e) {
      final error = mapPocketBaseError(e);
      if (error is ConflictException || error is NotFoundException) {
        return false;
      }
      throw error;
    }
  }
}
