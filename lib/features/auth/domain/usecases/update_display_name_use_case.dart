import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/auth_failures.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';
import '../validation/account_field_rules.dart';

/// Changes the signed-in user's display name. The new name arrives through the auth stream.
@lazySingleton
class UpdateDisplayNameUseCase
    implements UseCase<Unit, UpdateDisplayNameParams> {
  const UpdateDisplayNameUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(UpdateDisplayNameParams params) async {
    // REQ-006
    final user = _repository.currentUser();
    if (user == null) return const Left(UnauthenticatedFailure());
    // REQ-002, REQ-011
    final errors = checkDisplayNameChange(
      currentDisplayName: user.displayName,
      newDisplayName: params.displayName,
    );
    if (errors.isNotEmpty) return Left(InvalidAccountFieldsFailure(errors));
    return _repository.updateDisplayName(params.displayName.trim());
  }
}

class UpdateDisplayNameParams extends Equatable {
  const UpdateDisplayNameParams({required this.displayName});

  final String displayName;

  @override
  List<Object?> get props => [displayName];
}
