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

  /// Changes the signed-in user's e-mail. [email] is already normalized; the new
  /// user arrives through [authState]. // REQ-007
  Future<Either<Failure, Unit>> changeEmail({
    required String email,
    required String currentPassword,
  });

  /// Ends every other device's session and keeps this one. // REQ-009
  Future<Either<Failure, Unit>> signOutOtherDevices();

  /// Fluxo do estado de autenticação (`null` = deslogado).
  Stream<UserEntity?> authState();

  /// Usuário atual (síncrono), se houver sessão.
  UserEntity? currentUser();
}
