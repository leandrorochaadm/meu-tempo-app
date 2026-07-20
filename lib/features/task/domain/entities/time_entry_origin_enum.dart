import 'package:json_annotation/json_annotation.dart';

/// Origem de um registro de tempo. Serializado por `.name`.
@JsonEnum()
enum TimeEntryOriginEnum {
  timer,
  manual,
}
