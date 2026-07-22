import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/theme_context_extensions.dart';
import '../utils/formatters/duration_formatter.dart';

/// Selo do cronômetro ativo numa folha — exibe o tempo da **sessão atual** ao
/// vivo (hh:mm:ss), atualizado a cada segundo. Só é montado quando a tarefa
/// está rodando; o [Timer] existe apenas enquanto o selo está na árvore. O
/// espaçamento após o selo é responsabilidade de quem o posiciona.
class TaskRunningBadge extends StatefulWidget {
  const TaskRunningBadge({super.key, required this.startedAt});

  /// Início da sessão atual do cronômetro (do `ActiveTimerEntity`).
  final DateTime startedAt;

  @override
  State<TaskRunningBadge> createState() => _TaskRunningBadgeState();
}

class _TaskRunningBadgeState extends State<TaskRunningBadge> {
  Timer? _ticker;
  late int _elapsedSeconds;

  @override
  void initState() {
    super.initState();
    _recompute();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(_recompute);
    });
  }

  @override
  void didUpdateWidget(TaskRunningBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trocou a tarefa/sessão ativa: reinicia a contagem a partir do novo início.
    if (oldWidget.startedAt != widget.startedAt) {
      setState(_recompute);
    }
  }

  /// Segundos decorridos desde o início — derivação de apresentação de tempo
  /// (não é regra de negócio; a persistência mora no StopTimerUseCase).
  void _recompute() {
    final diff = DateTime.now().difference(widget.startedAt).inSeconds;
    _elapsedSeconds = diff < 0 ? 0 : diff;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timelapse_rounded, size: 14, color: context.colors.timerActive),
        SizedBox(width: context.space.xs),
        Text(
          DurationFormatter.hms(_elapsedSeconds),
          style: context.text.labelSmall,
        ),
      ],
    );
  }
}
