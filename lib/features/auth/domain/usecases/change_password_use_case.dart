import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/auth_failures.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';
import '../validation/account_field_rules.dart';

/// Changes the signed-in user's password, then ends the other devices' sessions.
@lazySingleton
class ChangePasswordUseCase implements UseCase<Unit, ChangePasswordParams> {
  const ChangePasswordUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ChangePasswordParams params) async {
    // REQ-008
    final errors = checkNewPassword(
      currentPassword: params.currentPassword,
      newPassword: params.newPassword,
    );
    if (errors.isNotEmpty) return Left(InvalidAccountFieldsFailure(errors));
    final changed = await _repository.changePassword(
      currentPassword: params.currentPassword,
      newPassword: params.newPassword,
    );
    if (changed.isLeft()) return changed;
    // REQ-009
    return _repository.signOutOtherDevices();
  }
}

class ChangePasswordParams extends Equatable {
  const ChangePasswordParams({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  @override
  List<Object?> get props => [currentPassword, newPassword];
}
