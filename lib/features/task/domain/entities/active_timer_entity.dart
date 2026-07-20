import 'package:equatable/equatable.dart';

/// Cronômetro ativo do usuário (no máximo 1 por vez). Aponta para a folha
/// (ou compromisso) em contagem e quando começou.
class ActiveTimerEntity extends Equatable {
  const ActiveTimerEntity({
    required this.targetId,
    required this.startedAt,
  });

  final String targetId;
  final DateTime startedAt;

  /// Minutos decorridos até [now] (arredondado para baixo).
  int elapsedMinutes(DateTime now) {
    final diff = now.difference(startedAt).inMinutes;
    return diff < 0 ? 0 : diff;
  }

  @override
  List<Object?> get props => [targetId, startedAt];
}
