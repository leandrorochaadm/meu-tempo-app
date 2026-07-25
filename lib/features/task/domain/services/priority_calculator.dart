import '../entities/importance_enum.dart';
import '../entities/task_entity.dart';
import '../entities/urgency_band_enum.dart';

/// Fórmula de prioridade da folha:
/// `tempoEstimado × (5 − importância) × urgênciaDoPrazo`.
///
/// Depende de `today` (dado externo), por isso vive no domínio como serviço —
/// não como getter intrínseco da Entity (ver `architecture.md`). Compartilhada
/// pela listagem por prioridade e pela barra do cronômetro ativo.
class PriorityCalculator {
  const PriorityCalculator._();

  static int of(TaskEntity task, DateTime today) {
    final t0 = DateTime(today.year, today.month, today.day);
    final estimated = task.estimatedMinutes ?? 0;
    final importance = (task.importance ?? ImportanceEnum.min).value;
    return estimated * (5 - importance) * _urgency(task.dueDate, t0).weight;
  }

  static UrgencyBandEnum _urgency(DateTime? dueDate, DateTime today) {
    if (dueDate == null) return UrgencyBandEnum.beyondFourteen;
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return UrgencyBandEnum.fromDaysUntilDue(due.difference(today).inDays);
  }
}
