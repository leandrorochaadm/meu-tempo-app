import 'package:equatable/equatable.dart';

import 'report_period_enum.dart';

/// Intervalo `[start, end)` de um período de relatório. Cálculo de datas isolado
/// aqui para ser testável (evita lógica de data espalhada no Bloc).
class PeriodRange extends Equatable {
  const PeriodRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  /// Constrói o intervalo do [period] contendo o instante [now].
  ///
  /// - `day`: da meia-noite de hoje à meia-noite de amanhã.
  /// - `week`: de segunda-feira (00h) à segunda seguinte (semana ISO).
  /// - `month`: do dia 1 (00h) ao dia 1 do mês seguinte.
  factory PeriodRange.of(ReportPeriodEnum period, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (period) {
      case ReportPeriodEnum.day:
        return PeriodRange(start: today, end: today.add(const Duration(days: 1)));
      case ReportPeriodEnum.week:
        // weekday: 1 = segunda ... 7 = domingo.
        final monday = today.subtract(Duration(days: today.weekday - 1));
        return PeriodRange(
          start: monday,
          end: monday.add(const Duration(days: 7)),
        );
      case ReportPeriodEnum.month:
        final start = DateTime(now.year, now.month);
        final end = DateTime(now.year, now.month + 1);
        return PeriodRange(start: start, end: end);
    }
  }

  @override
  List<Object?> get props => [start, end];
}
