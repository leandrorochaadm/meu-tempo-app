import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

/// Converte `Timestamp` (Firestore) ↔ `DateTime` (Dart) para os Models
/// anotados com `json_serializable`. Usado via `@TimestampConverter()`.
///
/// Como o mapa vem cru do Firestore (com objetos `Timestamp`), o `fromJson`
/// recebe `Timestamp` e o `toJson` gera `Timestamp` — gravável direto.
class TimestampConverter implements JsonConverter<DateTime?, Timestamp?> {
  const TimestampConverter();

  @override
  DateTime? fromJson(Timestamp? ts) => ts?.toDate();

  @override
  Timestamp? toJson(DateTime? date) =>
      date == null ? null : Timestamp.fromDate(date);
}
