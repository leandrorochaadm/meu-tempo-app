import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../list/domain/entities/task_list_entity.dart';
import '../../domain/entities/quick_add_target_entity.dart';

/// Barra de criação rápida **ancorada no topo** (nunca bottom-sheet — o teclado
/// jamais cobre o campo). Autofocus + ação "done" cria a tarefa e **reabre o
/// campo focado** para lançar várias em sequência (H12).
///
/// Dois botões de confirmação: `↑` só cria; `▶` cria e **já começa a contar o
/// tempo** na tarefa criada. O alvo (`target`) e a oferta de mãe
/// (`offeredParent`) chegam prontos do domínio — aqui só se exibe e dispara.
class QuickAddTaskWidget extends StatefulWidget {
  const QuickAddTaskWidget({
    super.key,
    required this.onSubmit,
    required this.onSubmitAndStart,
    this.target,
    this.offeredParent,
    this.onTargetChanged,
    this.lists = const [],
    this.selectedListId,
    this.onListSelected,
  });

  /// Chamado com o título ao confirmar só a criação (`↑` ou ação "done").
  final void Function(String title) onSubmit;

  /// Chamado com o título ao criar **e** iniciar o cronômetro (`▶`).
  final void Function(String title) onSubmitAndStart;

  /// Alvo ativo: `null` = o lançamento vira tarefa mãe (raiz).
  final QuickAddTargetEntity? target;

  /// Última criada, oferecida como mãe do próximo lançamento.
  final QuickAddTargetEntity? offeredParent;

  /// Troca o alvo (`null` volta para tarefa mãe).
  final void Function(QuickAddTargetEntity? target)? onTargetChanged;

  /// Listas disponíveis (o seletor só aparece com 2+ e no modo raiz).
  final List<TaskListEntity> lists;
  final String? selectedListId;
  final void Function(String listId)? onListSelected;

  @override
  State<QuickAddTaskWidget> createState() => _QuickAddTaskWidgetState();
}

class _QuickAddTaskWidgetState extends State<QuickAddTaskWidget> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  void _confirm(void Function(String title) action) {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    action(title);
    _controller.clear();
    // Reabre o campo focado para o próximo lançamento em sequência.
    _focusNode.requestFocus();
  }

  /// Placeholder por nível do alvo — o termo do produto ("filha"/"neta").
  String get _hint => switch (widget.target?.level) {
    null => 'Nova tarefa…',
    0 => 'Nova filha…',
    _ => 'Nova neta…',
  };

  /// Rótulo do chip de alvo, pelo nível da mãe oferecida.
  String _targetChipLabel(QuickAddTargetEntity parent) => parent.level == 0
      ? 'filha de "${parent.title}"'
      : 'neta de "${parent.title}"';

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final target = widget.target;
    final offered = widget.offeredParent;
    // Filha herda a lista da mãe — no modo alvo não há o que escolher.
    final showListChips =
        target == null &&
        widget.lists.length > 1 &&
        widget.onListSelected != null;
    final parentChip = target ?? offered;

    return Container(
      padding: EdgeInsets.all(context.space.md),
      color: colors.surfaceHigh,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (target != null)
            _ContextBanner(
              target: target,
              onClear: () => widget.onTargetChanged?.call(null),
            ),
          _FieldSlot(
            indented: target != null,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _confirm(widget.onSubmit),
                    style: context.text.bodyMedium,
                    decoration: InputDecoration(
                      hintText: _hint,
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
                  onPressed: () => _confirm(widget.onSubmitAndStart),
                  icon: Icon(
                    Icons.play_arrow_rounded,
                    color: colors.timerActive,
                  ),
                  tooltip: 'Criar e começar agora',
                ),
                IconButton(
                  onPressed: () => _confirm(widget.onSubmit),
                  icon: Icon(Icons.arrow_upward_rounded, color: colors.primary),
                  tooltip: 'Adicionar',
                ),
              ],
            ),
          ),
          if (parentChip != null) ...[
            SizedBox(height: context.space.sm),
            Wrap(
              spacing: context.space.sm,
              children: [
                ChoiceChip(
                  label: const Text('Tarefa mãe'),
                  selected: target == null,
                  onSelected: (_) => widget.onTargetChanged?.call(null),
                ),
                ChoiceChip(
                  avatar: const Icon(Icons.subdirectory_arrow_right_rounded),
                  label: Text(_targetChipLabel(parentChip)),
                  selected: target != null,
                  onSelected: (_) => widget.onTargetChanged?.call(parentChip),
                ),
              ],
            ),
          ],
          if (showListChips) ...[
            SizedBox(height: context.space.sm),
            Wrap(
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
          ],
        ],
      ),
    );
  }
}

/// Campo da barra. No modo alvo ele entra indentado, com uma guia vertical à
/// esquerda — sinal visual de que o lançamento cai **dentro** da tarefa.
class _FieldSlot extends StatelessWidget {
  const _FieldSlot({required this.indented, required this.child});

  final bool indented;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!indented) return child;
    return Padding(
      padding: EdgeInsets.only(left: context.space.md),
      child: Container(
        padding: EdgeInsets.only(left: context.space.md),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: context.colors.border)),
        ),
        child: child,
      ),
    );
  }
}

/// Faixa de contexto: diz em voz alta dentro de quem o lançamento vai cair e
/// oferece o `✕` para voltar a criar tarefa mãe.
class _ContextBanner extends StatelessWidget {
  const _ContextBanner({required this.target, required this.onClear});

  final QuickAddTargetEntity target;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(
          Icons.subdirectory_arrow_right_rounded,
          color: colors.textSecondary,
        ),
        SizedBox(width: context.space.sm),
        Expanded(
          child: Text(
            'dentro de "${target.title}"',
            style: context.text.labelMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          onPressed: onClear,
          icon: Icon(Icons.close_rounded, color: colors.textSecondary),
          tooltip: 'Sair de dentro da tarefa',
        ),
      ],
    );
  }
}
