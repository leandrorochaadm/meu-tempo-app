import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_primary_button.dart';
import '../../domain/entities/importance_enum.dart';
import '../widgets/task_parent_picker.dart';
import 'edit_task_args.dart';

/// Resultado da edição devolvido via `Navigator.pop`. Campos exclusivos de
/// folha são `null` para uma tarefa mãe; os flags indicam se re-parent/conclusão
/// devem ser disparados (evitam escrita/propagação à toa).
class EditTaskResult {
  const EditTaskResult({
    required this.title,
    required this.estimatedMinutes,
    required this.dueDate,
    required this.importance,
    required this.listId,
    required this.newParentId,
    required this.parentChanged,
    required this.isDone,
    required this.doneChanged,
  });

  final String title;
  final int? estimatedMinutes;
  final DateTime? dueDate;
  final ImportanceEnum? importance;
  final String listId;
  final String? newParentId;
  final bool parentChanged;
  final bool isDone;
  final bool doneChanged;
}

/// Formulário de edição de tarefa — todas as propriedades. Título no topo;
/// lista, mãe, prazo, importância e conclusão via chips/switch (1 toque). O
/// tempo gasto é editado numa tela dedicada (CRUD de registros).
class EditTaskPage extends StatefulWidget {
  const EditTaskPage({super.key, required this.args, required this.today});

  final EditTaskArgs args;
  final DateTime today;

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  late final _task = widget.args.task;
  late final TextEditingController _title =
      TextEditingController(text: _task.title);
  late String _listId = _task.listId;
  late int _estimated = _task.estimatedMinutes ?? 30;
  late ImportanceEnum _importance = _task.importance ?? ImportanceEnum.min;
  late DateTime _due = _task.dueDate ?? widget.today;
  late bool _isDone = _task.isDone;

  // Re-parent: só marca `_parentChanged` se o usuário escolher outra mãe.
  late String? _parentId = _task.parentId;
  late String _parentLabel = widget.args.currentParentLabel;
  bool _parentChanged = false;

  static const _minuteOptions = [15, 30, 60, 120];

  bool get _isLeaf => !_task.hasChildren;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickParent() async {
    final chosen =
        await showTaskParentPicker(context, widget.args.parentCandidates);
    if (chosen == null) return;
    setState(() {
      _parentChanged = true;
      if (chosen == kMakeRootSentinel) {
        _parentId = null;
        _parentLabel = '';
      } else {
        _parentId = chosen;
        final match =
            widget.args.parentCandidates.where((c) => c.id == chosen);
        _parentLabel = match.isEmpty ? '' : match.first.title;
      }
    });
  }

  Future<void> _openTimeEntries() =>
      context.push(Routes.timeEntry, extra: _task);

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(EditTaskResult(
      title: title,
      estimatedMinutes: _isLeaf ? _estimated : null,
      dueDate: _isLeaf ? _due : null,
      importance: _isLeaf ? _importance : null,
      listId: _listId,
      newParentId: _parentId,
      parentChanged: _parentChanged,
      isDone: _isDone,
      doneChanged: _isLeaf && _isDone != _task.isDone,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final labels = {
      ImportanceEnum.max: 'Máxima',
      ImportanceEnum.high: 'Alta',
      ImportanceEnum.low: 'Baixa',
      ImportanceEnum.min: 'Mínima',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Editar tarefa')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(context.space.lg),
          children: [
            TextField(
              controller: _title,
              autofocus: true,
              style: context.text.bodyMedium,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            SizedBox(height: context.space.xl),
            Text('Lista', style: context.text.labelLarge),
            SizedBox(height: context.space.sm),
            Wrap(
              spacing: context.space.sm,
              children: [
                for (final list in widget.args.lists)
                  ChoiceChip(
                    label: Text(list.name),
                    selected: _listId == list.id,
                    onSelected: (_) => setState(() => _listId = list.id),
                  ),
              ],
            ),
            SizedBox(height: context.space.xl),
            Text('Tarefa mãe', style: context.text.labelLarge),
            SizedBox(height: context.space.sm),
            OutlinedButton.icon(
              icon: const Icon(Icons.account_tree_rounded, size: 18),
              label: Text(_parentLabel.isEmpty
                  ? 'Nenhuma (é tarefa mãe)'
                  : _parentLabel),
              onPressed: _pickParent,
            ),
            if (_isLeaf) ...[
              SizedBox(height: context.space.xl),
              Text('Tempo estimado', style: context.text.labelLarge),
              SizedBox(height: context.space.sm),
              Wrap(
                spacing: context.space.sm,
                children: [
                  for (final m in _minuteOptions)
                    ChoiceChip(
                      label: Text('$m min'),
                      selected: _estimated == m,
                      onSelected: (_) => setState(() => _estimated = m),
                    ),
                ],
              ),
              SizedBox(height: context.space.xl),
              Text('Importância', style: context.text.labelLarge),
              SizedBox(height: context.space.sm),
              Wrap(
                spacing: context.space.sm,
                children: [
                  for (final imp in ImportanceEnum.values)
                    ChoiceChip(
                      label: Text(labels[imp]!),
                      selected: _importance == imp,
                      onSelected: (_) => setState(() => _importance = imp),
                    ),
                ],
              ),
              SizedBox(height: context.space.xl),
              Text('Prazo', style: context.text.labelLarge),
              SizedBox(height: context.space.sm),
              Wrap(
                spacing: context.space.sm,
                children: [
                  for (final entry in {
                    'Hoje': 0,
                    'Amanhã': 1,
                    '+7 dias': 7,
                  }.entries)
                    ChoiceChip(
                      label: Text(entry.key),
                      selected:
                          _due.difference(widget.today).inDays == entry.value,
                      onSelected: (_) => setState(() =>
                          _due = widget.today.add(Duration(days: entry.value))),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: const Text('Escolher data…'),
                    onPressed: _pickDate,
                  ),
                ],
              ),
              SizedBox(height: context.space.xl),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Concluída', style: context.text.labelLarge),
                value: _isDone,
                onChanged: (v) => setState(() => _isDone = v),
              ),
              SizedBox(height: context.space.sm),
              OutlinedButton.icon(
                icon: const Icon(Icons.schedule_rounded, size: 18),
                label: const Text('Ajustar tempo gasto'),
                onPressed: _openTimeEntries,
              ),
            ],
            SizedBox(height: context.space.xxxl),
            AppPrimaryButton(label: 'Salvar', onPressed: _save),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime(widget.today.year - 1),
      lastDate: DateTime(widget.today.year + 5),
    );
    if (picked != null) setState(() => _due = picked);
  }
}
