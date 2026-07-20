import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../list/domain/entities/task_list_entity.dart';

/// Barra de criação rápida **ancorada no topo** (nunca bottom-sheet — o teclado
/// jamais cobre o campo). Autofocus + ação "done" cria a tarefa e **reabre o
/// campo focado** para lançar várias em sequência (H12). Quando há 2+ listas,
/// mostra chips para escolher onde criar (H5/H11).
class QuickAddTaskWidget extends StatefulWidget {
  const QuickAddTaskWidget({
    super.key,
    required this.onSubmit,
    this.hint = 'Nova tarefa…',
    this.lists = const [],
    this.selectedListId,
    this.onListSelected,
  });

  /// Chamado com o título quando o usuário confirma (ação "done").
  final void Function(String title) onSubmit;

  /// Texto do placeholder (muda ao adicionar subtarefa).
  final String hint;

  /// Listas disponíveis (o seletor só aparece com 2+).
  final List<TaskListEntity> lists;
  final String? selectedListId;
  final void Function(String listId)? onListSelected;

  @override
  State<QuickAddTaskWidget> createState() => _QuickAddTaskWidgetState();
}

class _QuickAddTaskWidgetState extends State<QuickAddTaskWidget> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    widget.onSubmit(title);
    _controller.clear();
    // Reabre o campo focado para o próximo lançamento em sequência.
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final showListChips =
        widget.lists.length > 1 && widget.onListSelected != null;
    return Container(
      padding: EdgeInsets.all(context.space.md),
      color: colors.surfaceHigh,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              style: context.text.bodyMedium,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: context.text.bodySmall,
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: context.radius.mdRadius,
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.space.lg,
                  vertical: context.space.md,
                ),
              ),
            ),
          ),
          SizedBox(width: context.space.sm),
          IconButton(
            onPressed: _submit,
            icon: Icon(Icons.arrow_upward_rounded, color: colors.primary),
            tooltip: 'Adicionar',
          ),
            ],
          ),
          if (showListChips) ...[
            SizedBox(height: context.space.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: context.space.sm,
                children: [
                  for (final l in widget.lists)
                    ChoiceChip(
                      label: Text(l.name),
                      selected: widget.selectedListId == l.id,
                      onSelected: (_) => widget.onListSelected!(l.id),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
