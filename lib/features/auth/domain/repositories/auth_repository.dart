import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

/// Contrato de autenticação. Implementado na camada `data`.
abstract class AuthRepository {
  /// Inicia o login via SSO Google (redirect no Web). Retorna `Unit` no sucesso:
  /// o usuário autenticado chega pelo [authState], não por este retorno.
  Future<Either<Failure, Unit>> signInWithGoogle();

  /// Encerra a sessão.
  Future<Either<Failure, Unit>> signOut();

  /// Fluxo do estado de autenticação (`null` = deslogado).
  Stream<UserEntity?> authState();

  /// Usuário atual (síncrono), se houver sessão.
  UserEntity? currentUser();
}
