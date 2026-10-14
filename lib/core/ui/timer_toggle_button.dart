import 'package:flutter/material.dart';

import '../theme/theme_context_extensions.dart';

/// Botão de ícone que inicia/para o cronômetro (tarefa ou compromisso).
/// Mantém o alvo de toque padrão de 48 dp.
class TimerToggleButton extends StatelessWidget {
  const TimerToggleButton({
    super.key,
    required this.isActive,
    required this.onPressed,
  });

  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        isActive ? Icons.stop_circle_rounded : Icons.play_circle_rounded,
        color: isActive ? colors.timerActive : colors.primary,
      ),
      tooltip: isActive ? 'Parar cronômetro' : 'Iniciar cronômetro',
    );
  }
}
