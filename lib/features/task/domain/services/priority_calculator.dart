import '../entities/effort_band_enum.dart';
import '../entities/importance_enum.dart';
import '../entities/priority_breakdown.dart';
import '../entities/task_entity.dart';
import '../entities/urgency_band_enum.dart';

/// Fórmula de prioridade da folha:
/// `faixaDeEsforço × (5 − importância) × urgênciaDoPrazo`.
///
/// O tempo estimado entra pela **faixa** ([EffortBandEnum], peso 1–4) e não em
/// minutos crus, para ficar na mesma escala da importância e da urgência.
///
/// A urgência usa faixas até 14 dias e, em atraso, cresce 1 por dia atrasado sem
/// teto (ver [UrgencyBandEnum.weightForDaysUntilDue]).
///
/// Depende de `today` (dado externo), por isso vive no domínio como serviço —
/// não como getter intrínseco da Entity (ver `architecture.md`). Compartilhada
/// pela listagem por prioridade e pela barra do cronômetro ativo.
class PriorityCalculator {
  const PriorityCalculator._();

  static int of(TaskEntity task, DateTime today) =>
      breakdownOf(task, today).total;

  /// Detalhamento com cada fator resolvido — alimenta a explicação do cálculo
  /// na UI sem que ela precise calcular nada.
  static PriorityBreakdown breakdownOf(TaskEntity task, DateTime today) {
    final t0 = DateTime(today.year, today.month, today.day);
    final days = _daysUntilDue(task.dueDate, t0);
    return PriorityBreakdown(
      estimatedMinutes: task.estimatedMinutes ?? 0,
      importance: task.importance ?? ImportanceEnum.min,
      urgencyWeight: days == null
          ? UrgencyBandEnum.beyondFourteen.weight
          : UrgencyBandEnum.weightForDaysUntilDue(days),
      daysUntilDue: days,
    );
  }

  static int? _daysUntilDue(DateTime? dueDate, DateTime today) {
    if (dueDate == null) return null;
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }
}
