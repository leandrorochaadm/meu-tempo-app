import 'package:injectable/injectable.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../../core/constants/pb_schema.dart';
import '../../../../core/data/pocketbase/pocketbase_session.dart';
import '../../../../core/data/pocketbase/record_watcher.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/pocketbase_error_mapper.dart';
import '../../../../core/utils/calendar_date_codec.dart';
import '../models/appointment_model.dart';

abstract class AppointmentRemoteDataSource {
  Stream<List<AppointmentModel>> watchForDay(DateTime day);
  Stream<List<AppointmentModel>> watchAll();
  Future<AppointmentModel> create(AppointmentModel a);
  Future<void> delete(String id);
  Future<void> addSpentMinutes(String id, int minutes);

  /// Grava o estado de conclusão do compromisso (`true` conclui, `false` reabre).
  Future<void> setDone(String id, bool value);
}

@LazySingleton(as: AppointmentRemoteDataSource)
class AppointmentRemoteDataSourceImpl implements AppointmentRemoteDataSource {
  AppointmentRemoteDataSourceImpl(this._session, this._watcher);

  final PocketBaseSession _session;
  final RecordWatcher _watcher;

  RecordService get _records =>
      _session.client.collection(PbCollections.appointments);

  Future<List<AppointmentModel>> _fetch({
    String? filter,
    required String sort,
  }) async {
    try {
      final records = await _records.getFullList(filter: filter, sort: sort);
      return records.map(AppointmentModel.fromRecord).toList();
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  @override
  Stream<List<AppointmentModel>> watchForDay(DateTime day) {
    _session.userId;
    final filter = _session.client.filter('${PbFields.date} = {:d}', {
      'd': CalendarDateCodec.format(day),
    });
    return _watcher.watch(
      collection: PbCollections.appointments,
      load: () => _fetch(
        filter: filter,
        sort: '${PbFields.date},${PbFields.startMinute}',
      ),
    );
  }

  @override
  Stream<List<AppointmentModel>> watchAll() {
    _session.userId;
    return _watcher.watch(
      collection: PbCollections.appointments,
      load: () => _fetch(sort: PbFields.date),
    );
  }

  @override
  Future<AppointmentModel> create(AppointmentModel a) async {
    final userId = _session.userId;
    try {
      final record = await _records.create(
        body: {...a.toJson(), PbFields.user: userId},
      );
      return AppointmentModel.fromRecord(record);
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
  Future<void> addSpentMinutes(String id, int minutes) async {
    _session.userId;
    try {
      await _records.update(
        id,
        body: {PbFields.increment(PbFields.spentMinutes): minutes},
      );
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  @override
  Future<void> setDone(String id, bool value) async {
    _session.userId;
    try {
      await _records.update(id, body: {PbFields.isDone: value});
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }
}
