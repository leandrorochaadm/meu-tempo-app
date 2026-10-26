import 'package:injectable/injectable.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../../core/constants/pb_schema.dart';
import '../../../../core/data/pocketbase/pocketbase_session.dart';
import '../../../../core/data/pocketbase/record_watcher.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/pocketbase_error_mapper.dart';
import '../models/active_timer_model.dart';

abstract class TimerRemoteDataSource {
  Stream<ActiveTimerModel?> watchActive();
  Future<ActiveTimerModel?> getActive();
  Future<void> setActive(ActiveTimerModel timer);
  Future<ActiveTimerModel?> claimActive();

  /// Lê o registro e grava só se ele não mudou (apagar pelo `id` lido volta 404
  /// se mudou): se [matches] aceitar o atual (`null` = sem cronômetro), grava
  /// [replacement] e devolve `true`; senão não grava nada e devolve `false`.
  /// [matches] precisa ser puro.
  Future<bool> replaceActiveIf({
    required bool Function(ActiveTimerModel? current) matches,
    required ActiveTimerModel replacement,
  });

  /// Lê o registro e grava só se ele não mudou (apagar pelo `id` lido volta 404
  /// se mudou): se [matches] aceitar o atual (`null` = sem cronômetro), apaga o
  /// registro e devolve `true`; senão não apaga nada e devolve `false`.
  /// [matches] precisa ser puro.
  Future<bool> clearActiveIf({
    required bool Function(ActiveTimerModel? current) matches,
  });
  Future<void> clear();
}

@LazySingleton(as: TimerRemoteDataSource)
class TimerRemoteDataSourceImpl implements TimerRemoteDataSource {
  TimerRemoteDataSourceImpl(this._session, this._watcher);

  final PocketBaseSession _session;
  final RecordWatcher _watcher;

  RecordService get _records =>
      _session.client.collection(PbCollections.activeTimers);

  Future<RecordModel?> _fetchRecord() async {
    final page = await _records.getList(page: 1, perPage: 1, skipTotal: true);
    return page.items.isEmpty ? null : page.items.first;
  }

  Future<ActiveTimerModel?> _load() async {
    final record = await _fetchRecord();
    return record == null ? null : ActiveTimerModel.fromRecord(record);
  }

  @override
  Stream<ActiveTimerModel?> watchActive() {
    _session.userId;
    return _watcher.watch(collection: PbCollections.activeTimers, load: _load);
  }

  @override
  Future<ActiveTimerModel?> getActive() async {
    _session.userId;
    try {
      return await _load();
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  @override
  Future<void> setActive(ActiveTimerModel timer) async {
    final userId = _session.userId;
    try {
      final record = await _fetchRecord();
      if (record != null) {
        await _records.update(record.id, body: timer.toJson());
        return;
      }
      try {
        await _records.create(body: {...timer.toJson(), PbFields.user: userId});
      } on ClientException catch (e) {
        if (mapPocketBaseError(e) is! ConflictException) rethrow;
        // Another device created it between the read and the write: read
        // once more and overwrite (last writer wins).
        final created = await _fetchRecord();
        if (created == null) rethrow;
        await _records.update(created.id, body: timer.toJson());
      }
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  @override
  Future<ActiveTimerModel?> claimActive() async {
    _session.userId;
    try {
      // Reads and deletes by the id read. If two "Stop" race, a concurrent
      // delete of the same record answers 404 to one of them, so only one
      // caller receives the timer and records the time (idempotency).
      final record = await _fetchRecord();
      if (record == null) return null;
      final model = ActiveTimerModel.fromRecord(record);
      await _records.delete(record.id);
      return model;
    } on ClientException catch (e) {
      final error = mapPocketBaseError(e);
      if (error is NotFoundException) return null;
      throw error;
    }
  }

  @override
  Future<bool> replaceActiveIf({
    required bool Function(ActiveTimerModel? current) matches,
    required ActiveTimerModel replacement,
  }) async {
    final userId = _session.userId;
    try {
      // Delete (by the id read) then create, in one batch: if the record was
      // deleted or swapped after the read, the delete answers 404 and the
      // whole batch fails. The delete goes first because of UNIQUE (user).
      final record = await _fetchRecord();
      if (!matches(
        record == null ? null : ActiveTimerModel.fromRecord(record),
      )) {
        return false;
      }
      final batch = _session.client.createBatch();
      if (record != null) {
        batch.collection(PbCollections.activeTimers).delete(record.id);
      }
      batch
          .collection(PbCollections.activeTimers)
          .create(body: {...replacement.toJson(), PbFields.user: userId});
      await batch.send();
      return true;
    } on ClientException catch (e) {
      final error = mapPocketBaseError(e);
      if (error is NotFoundException || error is ConflictException) {
        return false;
      }
      throw error;
    }
  }

  @override
  Future<bool> clearActiveIf({
    required bool Function(ActiveTimerModel? current) matches,
  }) async {
    _session.userId;
    try {
      final record = await _fetchRecord();
      if (!matches(
        record == null ? null : ActiveTimerModel.fromRecord(record),
      )) {
        return false;
      }
      if (record == null) return true;
      await _records.delete(record.id);
      return true;
    } on ClientException catch (e) {
      final error = mapPocketBaseError(e);
      if (error is NotFoundException) return false;
      throw error;
    }
  }

  @override
  Future<void> clear() async {
    _session.userId;
    try {
      final record = await _fetchRecord();
      if (record == null) return;
      await _records.delete(record.id);
    } on ClientException catch (e) {
      final error = mapPocketBaseError(e);
      if (error is NotFoundException) return;
      throw error;
    }
  }
}
