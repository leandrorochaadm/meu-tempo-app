import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/auth_failures.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/account_data_repository.dart';
import '../repositories/auth_repository.dart';

/// Deletes the signed-in user's data and account, in the order the server
/// accepts: blocking records first, then the user (the rest goes by cascade).
/// The account is kept when the data deletion fails.
@lazySingleton
class DeleteAccountUseCase implements UseCase<Unit, NoParams> {
  const DeleteAccountUseCase(this._authRepository, this._accountDataRepository);

  final AuthRepository _authRepository;
  final AccountDataRepository _accountDataRepository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    if (_authRepository.currentUser() == null) {
      return const Left(UnauthenticatedFailure());
    }
    final records = await _accountDataRepository.deleteBlockingRecords();
    if (records.isLeft()) return records;
    // Local data is a convenience: failing to clear it does not stop the
    // deletion (the repository already logged it).
    await _accountDataRepository.clearLocalData();
    return _authRepository.deleteCurrentUser();
  }
}
