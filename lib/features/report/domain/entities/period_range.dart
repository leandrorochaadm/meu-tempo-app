import 'package:equatable/equatable.dart';

import 'report_period_enum.dart';

/// Intervalo `[start, end)` de um período de relatório. Cálculo de datas isolado
/// aqui para ser testável (evita lógica de data espalhada no Bloc).
class PeriodRange extends Equatable {
  const PeriodRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  /// Constrói o intervalo do [period] contendo o instante [now] (período atual).
  ///
  /// - `day`: da meia-noite de hoje à meia-noite de amanhã.
  /// - `week`: de segunda-feira (00h) à segunda seguinte (semana ISO).
  /// - `month`: do dia 1 (00h) ao dia 1 do mês seguinte.
  factory PeriodRange.of(ReportPeriodEnum period, DateTime now) =>
      PeriodRange.at(period, now, 0);

  /// Constrói o intervalo do [period] deslocado por [offset] passos a partir do
  /// que contém [now] (`0` = atual, `-1` = anterior, `1` = seguinte). Sem limite
  /// negativo. `DateTime` normaliza mês/dia fora do intervalo, então offsets
  /// grandes (e viradas de ano) funcionam sem tratamento especial.
  factory PeriodRange.at(ReportPeriodEnum period, DateTime now, int offset) {
    switch (period) {
      case ReportPeriodEnum.day:
        final start = DateTime(now.year, now.month, now.day + offset);
        return PeriodRange(start: start, end: start.add(const Duration(days: 1)));
      case ReportPeriodEnum.week:
        // weekday: 1 = segunda ... 7 = domingo.
        final today = DateTime(now.year, now.month, now.day);
        final monday = today.subtract(Duration(days: today.weekday - 1));
        final start = monday.add(Duration(days: 7 * offset));
        return PeriodRange(
          start: start,
          end: start.add(const Duration(days: 7)),
        );
      case ReportPeriodEnum.month:
        final start = DateTime(now.year, now.month + offset);
        final end = DateTime(now.year, now.month + offset + 1);
        return PeriodRange(start: start, end: end);
    }
  }

  @override
  List<Object?> get props => [start, end];
}
