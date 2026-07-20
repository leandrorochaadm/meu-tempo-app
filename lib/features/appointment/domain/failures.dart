import '../../../core/error/failures.dart';

/// Título de compromisso vazio.
class EmptyAppointmentTitleFailure extends Failure {
  const EmptyAppointmentTitleFailure();
}

/// Duração de compromisso inválida (≤ 0).
class InvalidAppointmentDurationFailure extends Failure {
  const InvalidAppointmentDurationFailure();
}
