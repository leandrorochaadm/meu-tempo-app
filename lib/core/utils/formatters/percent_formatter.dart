import 'package:intl/intl.dart';

/// Formata percentuais para exibição na UI (pt-BR, vírgula decimal).
///
/// Formatação **não** é regra de negócio, mas também não pode ser literal
/// espalhada na tela — vive aqui, no `core`.
class PercentFormatter {
  const PercentFormatter._();

  static final NumberFormat _oneDecimal = NumberFormat('0.0', 'pt_BR');

  /// `66.66` → "66,7%" · `100` → "100,0%" · `7.4` → "7,4%".
  static String decimal1(double percent) => '${_oneDecimal.format(percent)}%';
}
