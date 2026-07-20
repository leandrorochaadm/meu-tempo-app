import 'package:json_annotation/json_annotation.dart';

/// Importância da folha (1 = máxima … 4 = mínima). O `value` numérico é usado
/// na fórmula de prioridade `tempoEstimado × (5 − value) × urgência`.
///
/// Serializado por `.name` (nunca `.index`) — estável ao reordenar.
@JsonEnum()
enum ImportanceEnum {
  max(1),
  high(2),
  low(3),
  min(4);

  const ImportanceEnum(this.value);

  final int value;
}
