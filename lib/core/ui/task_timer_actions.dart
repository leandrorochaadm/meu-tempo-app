import 'package:flutter/material.dart';

import '../theme/theme_context_extensions.dart';

/// Ações de tempo de uma folha: iniciar/parar cronômetro e atalho de tempo
/// manual (+30 min). Reutilizado nas listagens (árvore e por prioridade).
class TaskTimerActions extends StatelessWidget {
  const TaskTimerActions({
    super.key,
    required this.isActive,
    required this.onToggleTimer,
    required this.onAddTime,
  });

  final bool isActive;
  final VoidCallback onToggleTimer;
  final VoidCallback onAddTime;

  /// Atalho de tempo manual padrão do produto.
  static const int quickMinutes = 30;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FilledButton.tonalIcon(
          onPressed: onToggleTimer,
          icon: Icon(
            isActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
            size: 18,
          ),
          label: Text(isActive ? 'Parar' : 'Iniciar'),
        ),
        SizedBox(width: context.space.sm),
        OutlinedButton(
          onPressed: onAddTime,
          child: const Text('+$quickMinutes min'),
        ),
      ],
    );
  }
}
