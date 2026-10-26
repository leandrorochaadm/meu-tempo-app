import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

/// Contrato de autenticação. Implementado na camada `data`.
abstract class AuthRepository {
  /// Signs in with e-mail and password. Returns `Unit` on success: the signed-in
  /// user arrives through [authState], not through this return value.
  Future<Either<Failure, Unit>> signInWithEmail(String email, String password);

  /// Encerra a sessão.
  Future<Either<Failure, Unit>> signOut();

  /// Fluxo do estado de autenticação (`null` = deslogado).
  Stream<UserEntity?> authState();

  /// Usuário atual (síncrono), se houver sessão.
  UserEntity? currentUser();
}
