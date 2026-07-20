import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/report/domain/entities/period_range.dart';
import 'package:meu_tempo/features/report/domain/entities/report_period_enum.dart';

void main() {
  // Segunda-feira, 20/07/2026, 14h37.
  final now = DateTime(2026, 7, 20, 14, 37);

  test('day: da meia-noite de hoje à meia-noite de amanhã', () {
    final r = PeriodRange.of(ReportPeriodEnum.day, now);
    expect(r.start, DateTime(2026, 7, 20));
    expect(r.end, DateTime(2026, 7, 21));
  });

  test('week: de segunda a segunda seguinte', () {
    final r = PeriodRange.of(ReportPeriodEnum.week, now);
    expect(r.start, DateTime(2026, 7, 20)); // segunda
    expect(r.end, DateTime(2026, 7, 27));
  });

  test('week: quando now é domingo, começa na segunda anterior', () {
    final sunday = DateTime(2026, 7, 26, 9);
    final r = PeriodRange.of(ReportPeriodEnum.week, sunday);
    expect(r.start, DateTime(2026, 7, 20));
    expect(r.end, DateTime(2026, 7, 27));
  });

  test('month: do dia 1 ao dia 1 do mês seguinte', () {
    final r = PeriodRange.of(ReportPeriodEnum.month, now);
    expect(r.start, DateTime(2026, 7));
    expect(r.end, DateTime(2026, 8));
  });
}
