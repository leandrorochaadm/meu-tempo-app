import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Expõe o fluxo do estado de autenticação para o guard/router e o Bloc.
@lazySingleton
class WatchAuthStateUseCase implements StreamUseCase<UserEntity?, NoParams> {
  const WatchAuthStateUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Stream<UserEntity?> call(NoParams params) => _repository.authState();
}
