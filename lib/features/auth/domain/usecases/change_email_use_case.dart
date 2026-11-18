import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/auth_failures.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';
import '../validation/account_field_rules.dart';
import 'normalize_email.dart';

/// Changes the signed-in user's e-mail, then ends the other devices' sessions.
@lazySingleton
class ChangeEmailUseCase implements UseCase<Unit, ChangeEmailParams> {
  const ChangeEmailUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ChangeEmailParams params) async {
    // REQ-007
    final user = _repository.currentUser();
    if (user == null) return const Left(UnauthenticatedFailure());
    final errors = checkEmailChange(
      currentEmail: user.email,
      newEmail: params.newEmail,
    );
    if (errors.isNotEmpty) return Left(InvalidAccountFieldsFailure(errors));
    final changed = await _repository.changeEmail(
      email: normalizeEmail(params.newEmail),
      currentPassword: params.currentPassword,
    );
    if (changed.isLeft()) return changed;
    // REQ-009
    return _repository.signOutOtherDevices();
  }
}

class ChangeEmailParams extends Equatable {
  const ChangeEmailParams({
    required this.newEmail,
    required this.currentPassword,
  });

  final String newEmail;
  final String currentPassword;

  @override
  List<Object?> get props => [newEmail, currentPassword];
}
