import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context_extensions.dart';

/// Barra de criação rápida **ancorada no topo** (nunca bottom-sheet — o teclado
/// jamais cobre o campo). Autofocus + ação "done" cria a tarefa e **reabre o
/// campo focado** para lançar várias em sequência (H12).
class QuickAddTaskWidget extends StatefulWidget {
  const QuickAddTaskWidget({super.key, required this.onSubmit});

  /// Chamado com o título quando o usuário confirma (ação "done").
  final void Function(String title) onSubmit;

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
    return Container(
      padding: EdgeInsets.all(context.space.md),
      color: colors.surfaceHigh,
      child: Row(
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
                hintText: 'Nova tarefa…',
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
    );
  }
}
