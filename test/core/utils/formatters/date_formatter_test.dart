import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meu_tempo/core/utils/formatters/date_formatter.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('pt_BR', null));

  final today = DateTime(2026, 7, 20);

  group('relativeLabelFull', () {
    test('Hoje / Ontem / Amanhã', () {
      expect(DateFormatter.relativeLabelFull(today, today), 'Hoje');
      expect(
        DateFormatter.relativeLabelFull(DateTime(2026, 7, 19), today),
        'Ontem',
      );
      expect(
        DateFormatter.relativeLabelFull(DateTime(2026, 7, 21), today),
        'Amanhã',
      );
    });

    test('fora da janela cai em dd/MM/yyyy', () {
      expect(
        DateFormatter.relativeLabelFull(DateTime(2026, 7, 10), today),
        '10/07/2026',
      );
    });
  });

  test('range: dd/MM – dd/MM (usa endExclusive - 1 dia)', () {
    // Semana 20–26/07 → end exclusivo 27/07.
    expect(
      DateFormatter.range(DateTime(2026, 7, 20), DateTime(2026, 7, 27)),
      '20/07 – 26/07',
    );
  });

  test('monthYear: "julho de 2026"', () {
    expect(DateFormatter.monthYear(DateTime(2026, 7)), 'julho de 2026');
  });
}
