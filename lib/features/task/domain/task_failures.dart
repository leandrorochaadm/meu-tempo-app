import '../../../core/error/failures.dart';

/// Título de tarefa vazio.
class EmptyTitleFailure extends Failure {
  const EmptyTitleFailure();
}

/// Tarefa não encontrada.
class TaskNotFoundFailure extends Failure {
  const TaskNotFoundFailure();
}
