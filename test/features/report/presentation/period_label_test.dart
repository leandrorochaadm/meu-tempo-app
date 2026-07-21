import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meu_tempo/features/report/domain/entities/period_range.dart';
import 'package:meu_tempo/features/report/domain/entities/report_period_enum.dart';
import 'package:meu_tempo/features/report/presentation/period_label.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('pt_BR', null));

  final now = DateTime(2026, 7, 20); // segunda

  String label(ReportPeriodEnum p, int offset) => reportPeriodLabel(
        p,
        PeriodRange.at(p, now, offset),
        now,
      );

  test('dia atual = "Hoje"; anterior = "Ontem"', () {
    expect(label(ReportPeriodEnum.day, 0), 'Hoje');
    expect(label(ReportPeriodEnum.day, -1), 'Ontem');
  });

  test('semana = intervalo dd/MM – dd/MM', () {
    expect(label(ReportPeriodEnum.week, 0), '20/07 – 26/07');
    expect(label(ReportPeriodEnum.week, -1), '13/07 – 19/07');
  });

  test('mês = "julho de 2026" / mês anterior', () {
    expect(label(ReportPeriodEnum.month, 0), 'julho de 2026');
    expect(label(ReportPeriodEnum.month, -1), 'junho de 2026');
  });
}
