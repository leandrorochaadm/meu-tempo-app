import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

/// Contrato de autenticação. Implementado na camada `data`.
abstract class AuthRepository {
  /// Login via SSO Google (popup no Web).
  Future<Either<Failure, UserEntity>> signInWithGoogle();

  /// Encerra a sessão.
  Future<Either<Failure, Unit>> signOut();

  /// Fluxo do estado de autenticação (`null` = deslogado).
  Stream<UserEntity?> authState();

  /// Usuário atual (síncrono), se houver sessão.
  UserEntity? currentUser();
}
