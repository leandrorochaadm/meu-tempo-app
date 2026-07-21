import 'package:flutter/material.dart';

import '../theme/theme_context_extensions.dart';

/// Selo "rodando" — indica cronômetro ativo numa folha. Reutilizado nas
/// listagens (árvore e por prioridade). O espaçamento após o selo é
/// responsabilidade de quem o posiciona.
class TaskRunningBadge extends StatelessWidget {
  const TaskRunningBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timelapse_rounded, size: 14, color: context.colors.timerActive),
        SizedBox(width: context.space.xs),
        Text('rodando', style: context.text.labelSmall),
      ],
    );
  }
}
