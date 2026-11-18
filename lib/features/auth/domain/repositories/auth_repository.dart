import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

/// Contrato de autenticação. Implementado na camada `data`.
abstract class AuthRepository {
  /// Signs in with e-mail and password. Returns `Unit` on success: the signed-in
  /// user arrives through [authState], not through this return value.
  Future<Either<Failure, Unit>> signInWithEmail(String email, String password);

  /// Creates the account and starts the session. The user arrives through
  /// [authState], not through this return value.
  Future<Either<Failure, Unit>> signUp({
    required String displayName,
    required String email,
    required String password,
  });

  /// Encerra a sessão.
  Future<Either<Failure, Unit>> signOut();

  /// Deletes the signed-in user's account record. The session ends on success.
  Future<Either<Failure, Unit>> deleteCurrentUser();

  /// Saves the signed-in user's display name. The new name arrives through [authState].
  Future<Either<Failure, Unit>> updateDisplayName(String displayName);

  /// Fluxo do estado de autenticação (`null` = deslogado).
  Stream<UserEntity?> authState();

  /// Usuário atual (síncrono), se houver sessão.
  UserEntity? currentUser();
}
