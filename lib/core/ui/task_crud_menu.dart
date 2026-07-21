import 'package:flutter/material.dart';

import '../theme/theme_context_extensions.dart';

/// Menu de ações CRUD de uma tarefa (Editar / Mover / Excluir), reutilizado
/// nas listagens (árvore e por prioridade).
class TaskCrudMenu extends StatelessWidget {
  const TaskCrudMenu({
    super.key,
    required this.onEdit,
    required this.onMove,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onMove;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: context.colors.textMuted),
      onSelected: (v) {
        switch (v) {
          case 'edit':
            onEdit();
          case 'move':
            onMove();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('Editar')),
        PopupMenuItem(value: 'move', child: Text('Mover')),
        PopupMenuItem(value: 'delete', child: Text('Excluir')),
      ],
    );
  }
}
