import 'package:equatable/equatable.dart';

import 'timer_target_type_enum.dart';

/// Cronômetro ativo do usuário (no máximo 1 por vez). Aponta para a folha
/// (ou compromisso) em contagem, sabe a qual lista ela pertence e quando começou.
class ActiveTimerEntity extends Equatable {
  const ActiveTimerEntity({
    required this.targetId,
    required this.targetType,
    required this.listId,
    required this.startedAt,
  });

  final String targetId;

  /// Discrimina se [targetId] é uma folha (tarefa) ou um compromisso — decide
  /// para qual repositório o tempo é somado ao pausar/parar.
  final TimerTargetTypeEnum targetType;

  /// Lista à qual o alvo pertence — usada para montar o registro de tempo
  /// (`TimeEntry`) sem I/O extra ao parar.
  final String listId;

  final DateTime startedAt;

  /// Minutos decorridos até [now] (arredondado para baixo).
  int elapsedMinutes(DateTime now) {
    final diff = now.difference(startedAt).inMinutes;
    return diff < 0 ? 0 : diff;
  }

  @override
  List<Object?> get props => [targetId, targetType, listId, startedAt];
}
