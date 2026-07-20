import 'package:equatable/equatable.dart';

/// Base de todas as falhas de domínio.
///
/// Não carrega `message` — o texto exibido é decidido na `presentation`
/// (mapeando o tipo do Failure para uma mensagem em PT).
abstract class Failure extends Equatable {
  const Failure();

  @override
  List<Object?> get props => const [];
}

/// Falha genérica de servidor/infra (fallback).
class ServerFailure extends Failure {
  const ServerFailure();
}

/// Falha de rede/conectividade.
class NetworkFailure extends Failure {
  const NetworkFailure();
}

/// Permissão negada pelo backend (regras do Firestore).
class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure();
}

/// Recurso não encontrado.
class NotFoundFailure extends Failure {
  const NotFoundFailure();
}
