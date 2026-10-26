import 'package:json_annotation/json_annotation.dart';

/// Conversão de **dia** (data sem hora) entre o app e o texto `date` do
/// PocketBase, gravado à meia-noite UTC. O app sempre usa o dia local.
abstract final class CalendarDateCodec {
  static final RegExp _pattern = RegExp(
    r'^\d{4}-\d{2}-\d{2}[ T]00:00:00\.000Z$',
  );

  /// `YYYY-MM-DD 00:00:00.000Z` com o ano/mês/dia de [day]; a hora é ignorada.
  static String format(DateTime day) {
    final year = day.year.toString().padLeft(4, '0');
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '$year-$month-$date 00:00:00.000Z';
  }

  /// Lê o texto e devolve o dia local. Lança [FormatException] se o texto não
  /// for exatamente meia-noite UTC de um dia que existe.
  static DateTime parse(String raw) {
    if (!_pattern.hasMatch(raw)) {
      throw FormatException('Invalid calendar date', raw);
    }
    final year = int.parse(raw.substring(0, 4));
    final month = int.parse(raw.substring(5, 7));
    final day = int.parse(raw.substring(8, 10));
    final result = DateTime(year, month, day);
    if (result.year != year || result.month != month || result.day != day) {
      throw FormatException('Nonexistent calendar date', raw);
    }
    return result;
  }
}

class CalendarDateConverter implements JsonConverter<DateTime?, String?> {
  const CalendarDateConverter();

  @override
  DateTime? fromJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return CalendarDateCodec.parse(raw);
  }

  @override
  String? toJson(DateTime? day) =>
      day == null ? null : CalendarDateCodec.format(day);
}
