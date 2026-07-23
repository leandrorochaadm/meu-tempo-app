import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/report/domain/entities/list_report.dart';
import 'package:meu_tempo/features/report/domain/entities/list_report_row.dart';

void main() {
  ListReportRow row(String id, {required int est, required int spent}) =>
      ListReportRow(
        listId: id,
        listName: id,
        estimatedMinutes: est,
        spentMinutes: spent,
      );

  test('totais somam estimado e real de todas as linhas', () {
    final report = ListReport([
      row('a', est: 60, spent: 90),
      row('b', est: 120, spent: 45),
    ]);

    expect(report.totalEstimatedMinutes, 180);
    expect(report.totalSpentMinutes, 135);
    expect(report.isEmpty, isFalse);
  });

  test('shareRatio e sharePercent = participação do item no total gasto', () {
    final a = row('a', est: 60, spent: 90);
    final b = row('b', est: 120, spent: 45);
    final report = ListReport([a, b]); // total gasto = 135

    expect(report.shareRatio(a), closeTo(0.6667, 0.0001));
    expect(report.shareRatio(b), closeTo(0.3333, 0.0001));
    expect(report.sharePercent(a), closeTo(66.67, 0.01));
    expect(report.sharePercent(b), closeTo(33.33, 0.01));
  });

  test('share é 0/null quando o total gasto é zero', () {
    final a = row('a', est: 60, spent: 0);
    final report = ListReport([a]);

    expect(report.shareRatio(a), 0);
    expect(report.sharePercent(a), isNull);
  });

  test('relatório vazio tem totais zero e isEmpty verdadeiro', () {
    final report = ListReport(const []);

    expect(report.totalEstimatedMinutes, 0);
    expect(report.totalSpentMinutes, 0);
    expect(report.isEmpty, isTrue);
  });

  test('rows é imutável', () {
    final report = ListReport([row('a', est: 10, spent: 10)]);

    expect(() => report.rows.add(row('b', est: 1, spent: 1)),
        throwsUnsupportedError);
  });
}
