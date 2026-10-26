import 'package:json_annotation/json_annotation.dart';

/// Importância da folha (1 = máxima … 4 = mínima). O `value` numérico é usado
/// na fórmula de prioridade `faixaDeEsforço × (5 − value) × urgência`.
///
/// A grafia externa é o [apiValue] (nunca `.name` nem `.index`); o
/// `json_serializable` usa o mesmo campo (`valueField`).
@JsonEnum(valueField: 'apiValue')
enum ImportanceEnum {
  max(1, 'max'),
  high(2, 'high'),
  low(3, 'low'),
  min(4, 'min');

  const ImportanceEnum(this.value, this.apiValue);

  final int value;
  final String apiValue;

  /// Converte o valor externo. Ausente ou desconhecido → `null`: quem lê
  /// decide se falha ou usa um padrão.
  static ImportanceEnum? fromApi(String? raw) {
    for (final importance in values) {
      if (importance.apiValue == raw) return importance;
    }
    return null;
  }
}
