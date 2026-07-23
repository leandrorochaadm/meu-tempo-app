import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meu_tempo/core/utils/formatters/percent_formatter.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  test('decimal1 formata com 1 casa decimal e vírgula (pt-BR)', () {
    expect(PercentFormatter.decimal1(66.666), '66,7%');
    expect(PercentFormatter.decimal1(100), '100,0%');
    expect(PercentFormatter.decimal1(7.4), '7,4%');
    expect(PercentFormatter.decimal1(0), '0,0%');
  });
}
