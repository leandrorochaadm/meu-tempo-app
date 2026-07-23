import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../list/domain/entities/task_list_entity.dart';

/// Barra de filtro por lista da tela principal. Mostra **um chip** com a lista
/// atual (ou "Todas as listas") e, ao tocar, abre um bottom sheet com as opções.
///
/// Fricção (`layout.md`): como a "Entrada" sempre existe, filtrar só faz sentido
/// com **2+ listas** — com menos que isso a barra não renderiza nada.
class ListFilterBar extends StatelessWidget {
  const ListFilterBar({
    super.key,
    required this.lists,
    required this.selectedListId,
    required this.onSelected,
  });

  final List<TaskListEntity> lists;

  /// Lista filtrada (`null` = "Todas as listas").
  final String? selectedListId;

  /// Chamado ao escolher uma opção (`null` = "Todas as listas").
  final void Function(String? listId) onSelected;

  static const String _allLabel = 'Todas as listas';

  String _labelFor(String? listId) {
    if (listId == null) return _allLabel;
    for (final l in lists) {
      if (l.id == listId) return l.name;
    }
    return _allLabel;
  }

  Future<void> _openPicker(BuildContext context) async {
    final chosen = await showModalBottomSheet<_FilterChoice>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _ListFilterSheet(
        lists: lists,
        selectedListId: selectedListId,
      ),
    );
    if (chosen != null) onSelected(chosen.listId);
  }

  @override
  Widget build(BuildContext context) {
    // Fricção: filtrar só faz sentido com 2+ listas (a "Entrada" sempre existe).
    if (lists.length < 2) return const SizedBox.shrink();
    return ActionChip(
      avatar: Icon(Icons.filter_list_rounded, color: context.colors.primary),
      label: Text(_labelFor(selectedListId)),
      onPressed: () => _openPicker(context),
    );
  }
}

/// Resultado do bottom sheet — envolve o `listId` para diferenciar "escolheu
/// Todas (null)" de "fechou sem escolher (retorno null do sheet)".
class _FilterChoice {
  const _FilterChoice(this.listId);
  final String? listId;
}

class _ListFilterSheet extends StatelessWidget {
  const _ListFilterSheet({required this.lists, required this.selectedListId});

  final List<TaskListEntity> lists;
  final String? selectedListId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.space.xl,
              0,
              context.space.xl,
              context.space.sm,
            ),
            child: Text('Filtrar por lista', style: context.text.titleMedium),
          ),
          _FilterOption(
            icon: Icons.all_inbox_rounded,
            label: 'Todas as listas',
            selected: selectedListId == null,
            onTap: () => Navigator.of(context).pop(const _FilterChoice(null)),
          ),
          const Divider(height: 1),
          for (final l in lists)
            _FilterOption(
              icon: Icons.folder_rounded,
              label: l.name,
              selected: selectedListId == l.id,
              onTap: () => Navigator.of(context).pop(_FilterChoice(l.id)),
            ),
          SizedBox(height: context.space.md),
        ],
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  const _FilterOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? context.colors.primary : context.colors.textSecondary;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: context.text.bodyMedium?.copyWith(
          color: selected ? context.colors.primary : null,
        ),
      ),
      trailing:
          selected ? Icon(Icons.check_rounded, color: context.colors.primary) : null,
      onTap: onTap,
    );
  }
}
