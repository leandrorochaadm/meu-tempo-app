import 'package:injectable/injectable.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../../core/constants/pb_schema.dart';
import '../../../../core/data/pocketbase/pocketbase_session.dart';
import '../../../../core/data/pocketbase/record_watcher.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/pocketbase_error_mapper.dart';
import '../../../../core/utils/instant_codec.dart';
import '../models/time_entry_model.dart';

abstract class TimeEntryRemoteDataSource {
  Future<void> add(TimeEntryModel entry);
  Stream<List<TimeEntryModel>> watchBetween(DateTime start, DateTime end);
  Stream<List<TimeEntryModel>> watchByTarget(String targetId);
  Future<void> update(TimeEntryModel entry);
  Future<void> delete(String id);
}

@LazySingleton(as: TimeEntryRemoteDataSource)
class TimeEntryRemoteDataSourceImpl implements TimeEntryRemoteDataSource {
  TimeEntryRemoteDataSourceImpl(this._session, this._watcher);

  final PocketBaseSession _session;
  final RecordWatcher _watcher;

  RecordService get _records =>
      _session.client.collection(PbCollections.timeEntries);

  Future<List<TimeEntryModel>> _fetch({
    required String filter,
    required String sort,
  }) async {
    final records = await _records.getFullList(filter: filter, sort: sort);
    return records.map(TimeEntryModel.fromRecord).toList();
  }

  @override
  Future<void> add(TimeEntryModel entry) async {
    final userId = _session.userId;
    try {
      await _records.create(body: {...entry.toJson(), PbFields.user: userId});
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  @override
  Stream<List<TimeEntryModel>> watchBetween(DateTime start, DateTime end) {
    _session.userId;
    final filter = _session.client.filter(
      '${PbFields.occurredAt} >= {:a} && ${PbFields.occurredAt} < {:b}',
      {'a': InstantCodec.format(start), 'b': InstantCodec.format(end)},
    );
    return _watcher.watch(
      collection: PbCollections.timeEntries,
      load: () => _fetch(filter: filter, sort: PbFields.occurredAt),
    );
  }

  @override
  Stream<List<TimeEntryModel>> watchByTarget(String targetId) {
    _session.userId;
    final filter = _session.client.filter('${PbFields.targetId} = {:t}', {
      't': targetId,
    });
    return _watcher.watch(
      collection: PbCollections.timeEntries,
      load: () => _fetch(filter: filter, sort: '-${PbFields.occurredAt}'),
    );
  }

  @override
  Future<void> update(TimeEntryModel entry) async {
    _session.userId;
    try {
      await _records.update(entry.id, body: entry.toJson());
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
}
