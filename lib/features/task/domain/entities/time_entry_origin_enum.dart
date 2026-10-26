import 'package:json_annotation/json_annotation.dart';

/// Origem de um registro de tempo. A grafia externa é o [apiValue] (nunca
/// `.name` nem `.index`); o `json_serializable` usa o mesmo campo.
@JsonEnum(valueField: 'apiValue')
enum TimeEntryOriginEnum {
  timer('timer'),
  manual('manual');

  const TimeEntryOriginEnum(this.apiValue);

  final String apiValue;

  /// Converte o valor externo. Ausente ou desconhecido → `null`.
  static TimeEntryOriginEnum? fromApi(String? raw) {
    for (final origin in values) {
      if (origin.apiValue == raw) return origin;
    }
    return null;
  }
}
