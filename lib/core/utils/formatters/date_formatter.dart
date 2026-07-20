import 'package:intl/intl.dart';

/// Formata datas para exibição na UI (pt-BR).
class DateFormatter {
  const DateFormatter._();

  /// `05/07` (dia/mês).
  static String short(DateTime d) => DateFormat('dd/MM', 'pt_BR').format(d);

  /// `05/07/2026`.
  static String full(DateTime d) => DateFormat('dd/MM/yyyy', 'pt_BR').format(d);

  /// Rótulo relativo curto para prazos: "Hoje", "Amanhã" ou `dd/MM`.
  static String relativeLabel(DateTime date, DateTime today) {
    final d = DateTime(date.year, date.month, date.day);
    final t = DateTime(today.year, today.month, today.day);
    final diff = d.difference(t).inDays;
    return switch (diff) {
      0 => 'Hoje',
      1 => 'Amanhã',
      -1 => 'Ontem',
      _ => short(date),
    };
  }
}
