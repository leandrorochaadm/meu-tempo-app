import '../../../core/error/failures.dart';

/// Título de tarefa vazio.
class EmptyTitleFailure extends Failure {
  const EmptyTitleFailure();
}

/// Tarefa não encontrada.
class TaskNotFoundFailure extends Failure {
  const TaskNotFoundFailure();
}

/// Excede os 3 níveis (mãe → filha → neta): neta não pode ter filhas.
class MaxLevelExceededFailure extends Failure {
  const MaxLevelExceededFailure();
}

/// Cronômetro/registro só é permitido em folha (ou compromisso), não em
/// tarefa com filhas.
class TimerOnNonLeafFailure extends Failure {
  const TimerOnNonLeafFailure();
}

/// Duração informada inválida (≤ 0).
class InvalidDurationFailure extends Failure {
  const InvalidDurationFailure();
}

/// Movimento inválido na hierarquia (para si mesmo ou para um descendente).
class InvalidMoveFailure extends Failure {
  const InvalidMoveFailure();
}
