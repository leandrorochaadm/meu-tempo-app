import 'package:injectable/injectable.dart';

import '../entities/day_fit.dart';

/// Verifica se o planejado (durações estimadas das tarefas + compromissos do
/// dia) **cabe** no tempo disponível. A soma vive aqui (domínio), não na UI.
/// É um **aviso**, não um bloqueio.
@lazySingleton
class CheckFitsInDayUseCase {
  const CheckFitsInDayUseCase();

  DayFit call({
    required List<int> taskDurations,
    required List<int> appointmentDurations,
    required int availableMinutes,
  }) {
    final planned = taskDurations.fold<int>(0, (s, m) => s + m) +
        appointmentDurations.fold<int>(0, (s, m) => s + m);
    return DayFit(plannedMinutes: planned, availableMinutes: availableMinutes);
  }
}
