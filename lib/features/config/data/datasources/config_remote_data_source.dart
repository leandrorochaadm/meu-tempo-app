import 'package:injectable/injectable.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../../core/constants/pb_schema.dart';
import '../../../../core/data/pocketbase/pocketbase_session.dart';
import '../../../../core/data/pocketbase/record_watcher.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/pocketbase_error_mapper.dart';
import '../models/day_config_model.dart';

abstract class ConfigRemoteDataSource {
  Stream<DayConfigModel> watchConfig();
  Future<DayConfigModel> getConfig();
  Future<void> setAvailableMinutes(int minutes);
  Future<void> markOnboarded();
}

@LazySingleton(as: ConfigRemoteDataSource)
class ConfigRemoteDataSourceImpl implements ConfigRemoteDataSource {
  ConfigRemoteDataSourceImpl(this._session, this._watcher);

  final PocketBaseSession _session;
  final RecordWatcher _watcher;

  RecordService get _records =>
      _session.client.collection(PbCollections.dayConfigs);

  /// The user has at most one record (`UNIQUE (user)`).
  Future<RecordModel?> _fetchRecord() async {
    _session.userId;
    try {
      final page = await _records.getList(perPage: 1, skipTotal: true);
      return page.items.isEmpty ? null : page.items.first;
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  @override
  Stream<DayConfigModel> watchConfig() {
    _session.userId;
    return _watcher.watch(
      collection: PbCollections.dayConfigs,
      load: getConfig,
    );
  }

  @override
  Future<DayConfigModel> getConfig() async {
    final record = await _fetchRecord();
    // No record yet → model defaults.
    return record == null
        ? const DayConfigModel()
        : DayConfigModel.fromRecord(record);
  }

  @override
  Future<void> setAvailableMinutes(int minutes) =>
      _upsert({PbFields.availableMinutesPerDay: minutes});

  @override
  Future<void> markOnboarded() => _upsert({PbFields.onboarded: true});

  Future<void> _update(String id, Map<String, dynamic> fields) async {
    try {
      await _records.update(id, body: fields);
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  Future<void> _upsert(Map<String, dynamic> fields) async {
    final existing = await _fetchRecord();
    if (existing != null) return _update(existing.id, fields);
    final userId = _session.userId;
    try {
      await _records.create(
        body: {
          ...const DayConfigModel().toJson(),
          ...fields,
          PbFields.user: userId,
        },
      );
    } on ClientException catch (e) {
      final error = mapPocketBaseError(e);
      if (error is! ConflictException) throw error;
      // Another device created it first: update that one, once.
      final created = await _fetchRecord();
      if (created == null) throw error;
      return _update(created.id, fields);
    }
  }
}
