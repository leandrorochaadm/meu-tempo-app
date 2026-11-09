import 'package:injectable/injectable.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../../core/constants/pb_schema.dart';
import '../../../../core/data/pocketbase/pocketbase_session.dart';
import '../../../../core/error/pocketbase_error_mapper.dart';
import '../../../task/data/models/task_model.dart';
import '../../../task/data/task_batch_order.dart';

/// Same as `settings.batch.maxRequests` in `1792900100_settings.js`.
const int _maxBatchRequests = 500;

/// Deletes the records that block the account deletion. Throws
/// [AppException] on error.
abstract class AccountDataRemoteDataSource {
  /// Deletes all the user's tasks (children before parents) and then the
  /// recurring tasks, in batches.
  Future<void> deleteBlockingRecords();
}

@LazySingleton(as: AccountDataRemoteDataSource)
class AccountDataRemoteDataSourceImpl implements AccountDataRemoteDataSource {
  AccountDataRemoteDataSourceImpl(this._session);

  final PocketBaseSession _session;

  @override
  Future<void> deleteBlockingRecords() async {
    _session.userId;
    try {
      final tasks = await _session.client
          .collection(PbCollections.tasks)
          .getFullList();
      final recurring = await _session.client
          .collection(PbCollections.recurringTasks)
          .getFullList();
      final ordered = orderParentsFirst(
        tasks.map(TaskModel.fromRecord).toList(),
      ).reversed;
      final deletions = [
        for (final task in ordered) (PbCollections.tasks, task.id),
        for (final record in recurring)
          (PbCollections.recurringTasks, record.id),
      ];
      for (
        var start = 0;
        start < deletions.length;
        start += _maxBatchRequests
      ) {
        final batch = _session.client.createBatch();
        for (final (collection, id)
            in deletions.skip(start).take(_maxBatchRequests)) {
          batch.collection(collection).delete(id);
        }
        await batch.send();
      }
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }
}
