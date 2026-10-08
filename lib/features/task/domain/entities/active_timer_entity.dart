import 'package:equatable/equatable.dart';

import 'timer_status_enum.dart';
import 'timer_target_type_enum.dart';

/// Cronômetro ativo do usuário (no máximo 1 por vez). Aponta para a folha
/// (ou compromisso) em contagem — ou pausada —, sabe a qual lista ela pertence
/// e quando a sessão atual começou.
class ActiveTimerEntity extends Equatable {
  const ActiveTimerEntity({
    required this.targetId,
    required this.targetType,
    required this.listId,
    required this.startedAt,
    this.status = TimerStatusEnum.running,
  });

  final String targetId;

  /// Discrimina se [targetId] é uma folha (tarefa) ou um compromisso — decide
  /// para qual repositório o tempo é somado ao pausar/parar.
  final TimerTargetTypeEnum targetType;

  /// Lista à qual o alvo pertence — usada para montar o registro de tempo
  /// (`TimeEntry`) sem I/O extra ao parar.
  final String listId;

  /// Rodando: início da sessão atual (base do contador). Pausado: instante da
  /// pausa — a sessão já foi somada ao alvo e não conta mais.
  final DateTime startedAt;

  final TimerStatusEnum status;

  bool get isRunning => status == TimerStatusEnum.running;

  bool get isPaused => status == TimerStatusEnum.paused;

  /// Minutos da sessão atual até [now] (arredondado para baixo). Pausado → 0:
  /// o tempo da sessão já entrou no alvo ao pausar.
  int elapsedMinutes(DateTime now) {
    if (isPaused) return 0;
    final diff = now.difference(startedAt).inMinutes;
    return diff < 0 ? 0 : diff;
  }

  @override
  List<Object?> get props => [targetId, targetType, listId, startedAt, status];
}
