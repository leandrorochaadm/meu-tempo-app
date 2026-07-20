import '../../../core/error/failures.dart';

/// Nome de lista vazio.
class EmptyListNameFailure extends Failure {
  const EmptyListNameFailure();
}

/// Não é permitido excluir a lista fixa "Entrada".
class CannotDeleteInboxFailure extends Failure {
  const CannotDeleteInboxFailure();
}

/// Lista não encontrada.
class ListNotFoundFailure extends Failure {
  const ListNotFoundFailure();
}
