import 'package:json_annotation/json_annotation.dart';

/// Tipo de alvo do cronômetro ativo: folha (tarefa) ou compromisso.
/// Serializado por `.name` (nunca por índice).
@JsonEnum()
enum TimerTargetTypeEnum {
  task,
  appointment,
}
