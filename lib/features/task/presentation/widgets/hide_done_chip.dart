import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context_extensions.dart';

/// Chip que alterna ocultar/mostrar as tarefas concluídas na tela principal.
/// O rótulo descreve **a ação** do toque: quando estão ocultas mostra
/// "Mostrar concluídas"; quando visíveis, "Ocultar concluídas".
class HideDoneChip extends StatelessWidget {
  const HideDoneChip({
    super.key,
    required this.hideDone,
    required this.onChanged,
  });

  /// Se as concluídas estão ocultas agora.
  final bool hideDone;

  /// Chamado com o novo valor de "ocultar" ao tocar.
  final void Function(bool hide) onChanged;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(
        hideDone ? Icons.visibility_rounded : Icons.visibility_off_rounded,
        color: context.colors.primary,
      ),
      label: Text(hideDone ? 'Mostrar concluídas' : 'Ocultar concluídas'),
      onPressed: () => onChanged(!hideDone),
    );
  }
}
