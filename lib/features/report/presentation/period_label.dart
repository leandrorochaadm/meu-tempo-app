import '../../../core/utils/formatters/date_formatter.dart';
import '../domain/entities/period_range.dart';
import '../domain/entities/report_period_enum.dart';

/// Monta o rótulo do período para os cabeçalhos de navegação do relatório.
/// A seleção "dia→relativo, semana→intervalo, mês→mês/ano" conhece o
/// `ReportPeriodEnum` (de feature), por isso vive aqui e não no `core`
/// (formatação, não regra de negócio; usa apenas as peças genéricas do core).
String reportPeriodLabel(
  ReportPeriodEnum period,
  PeriodRange range,
  DateTime today,
) =>
    switch (period) {
      ReportPeriodEnum.day => DateFormatter.relativeLabelFull(range.start, today),
      ReportPeriodEnum.week => DateFormatter.range(range.start, range.end),
      ReportPeriodEnum.month => DateFormatter.monthYear(range.start),
    };
