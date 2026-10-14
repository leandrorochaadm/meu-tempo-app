import 'package:flutter/material.dart';

import '../constants/app_defaults.dart';
import '../theme/theme_context_extensions.dart';

enum _TaskCrudActionEnum { edit, move, addSubtask, addTime, delete }

/// Menu de ações CRUD de uma tarefa (Editar / Mover / Excluir), reutilizado
/// nas listagens (árvore e por prioridade). Os itens "Adicionar subtarefa" e
/// "Somar tempo" são opcionais: só aparecem quando o callback é informado.
class TaskCrudMenu extends StatelessWidget {
  const TaskCrudMenu({
    super.key,
    required this.onEdit,
    required this.onMove,
    required this.onDelete,
    this.onAddSubtask,
    this.onAddTime,
  });

  final VoidCallback onEdit;
  final VoidCallback onMove;
  final VoidCallback onDelete;
  final VoidCallback? onAddSubtask;
  final VoidCallback? onAddTime;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_TaskCrudActionEnum>(
      icon: Icon(Icons.more_vert_rounded, color: context.colors.textMuted),
      onSelected: (action) {
        switch (action) {
          case _TaskCrudActionEnum.edit:
            onEdit();
          case _TaskCrudActionEnum.move:
            onMove();
          case _TaskCrudActionEnum.addSubtask:
            onAddSubtask!();
          case _TaskCrudActionEnum.addTime:
            onAddTime!();
          case _TaskCrudActionEnum.delete:
            onDelete();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _TaskCrudActionEnum.edit,
          child: Text('Editar'),
        ),
        const PopupMenuItem(
          value: _TaskCrudActionEnum.move,
          child: Text('Mover'),
        ),
        if (onAddSubtask != null)
          const PopupMenuItem(
            value: _TaskCrudActionEnum.addSubtask,
            child: Text('Adicionar subtarefa'),
          ),
        if (onAddTime != null)
          PopupMenuItem(
            value: _TaskCrudActionEnum.addTime,
            child: Text('Somar ${AppDefaults.quickAddTimeMinutes} min'),
          ),
        const PopupMenuItem(
          value: _TaskCrudActionEnum.delete,
          child: Text('Excluir'),
        ),
      ],
    );
  }
}
