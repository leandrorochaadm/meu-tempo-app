import 'package:json_annotation/json_annotation.dart';

/// Conversão de **instante** (data e hora) entre o app (hora local) e o texto
/// `date` do PocketBase (sempre UTC).
abstract final class InstantCodec {
  static final RegExp _pattern = RegExp(
    r'^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}(\.\d{1,6})?Z$',
  );

  /// `YYYY-MM-DD HH:mm:ss.SSSZ` em UTC; microssegundos são descartados.
  static String format(DateTime instant) {
    final utc = instant.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    final year = utc.year.toString().padLeft(4, '0');
    final millis = utc.millisecond.toString().padLeft(3, '0');
    return '$year-${two(utc.month)}-${two(utc.day)} '
        '${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)}.${millis}Z';
  }

  /// Lê o texto (com `Z` obrigatório) e devolve o instante em hora local.
  /// Lança [FormatException] fora do formato.
  static DateTime parse(String raw) {
    if (!_pattern.hasMatch(raw)) {
      throw FormatException('Invalid instant', raw);
    }
    return DateTime.parse(raw.replaceFirst(' ', 'T')).toLocal();
  }
}

class InstantConverter implements JsonConverter<DateTime?, String?> {
  const InstantConverter();

  @override
  DateTime? fromJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return InstantCodec.parse(raw);
  }

  @override
  String? toJson(DateTime? instant) =>
      instant == null ? null : InstantCodec.format(instant);
}
