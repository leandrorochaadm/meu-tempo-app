import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';

/// User data that must go before the account itself. Implemented in `data`.
abstract class AccountDataRepository {
  /// Deletes the user's tasks and recurring tasks, which block the account
  /// deletion on the server. Everything else goes by cascade when the user
  /// record is deleted.
  Future<Either<Failure, Unit>> deleteBlockingRecords();

  /// Clears the user's data stored on this device.
  Future<Either<Failure, Unit>> clearLocalData();
}
