import 'package:intl/intl.dart';

/// Formata datas para exibição na UI (pt-BR).
class DateFormatter {
  const DateFormatter._();

  /// Como [relativeLabel], mas cai em `dd/MM/yyyy` (ano incluso) fora da janela
  /// Ontem/Hoje/Amanhã — usado na navegação de período (pode voltar meses).
  static String relativeLabelFull(DateTime date, DateTime today) {
    final d = DateTime(date.year, date.month, date.day);
    final t = DateTime(today.year, today.month, today.day);
    return switch (d.difference(t).inDays) {
      0 => 'Hoje',
      1 => 'Amanhã',
      -1 => 'Ontem',
      _ => full(date),
    };
  }

  /// Intervalo curto "dd/MM – dd/MM" (usado na semana). [endExclusive] é o fim
  /// exclusivo (`PeriodRange.end`); o último dia visível é `endExclusive - 1`.
  static String range(DateTime start, DateTime endExclusive) {
    final lastDay = endExclusive.subtract(const Duration(days: 1));
    return '${short(start)} – ${short(lastDay)}';
  }

  /// "julho de 2026" (usado no mês).
  static String monthYear(DateTime d) =>
      DateFormat("MMMM 'de' yyyy", 'pt_BR').format(d);

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
