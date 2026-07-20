import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_primary_button.dart';
import '../../domain/entities/importance_enum.dart';
import '../../domain/entities/task_entity.dart';

/// Resultado da edição devolvido via `Navigator.pop`.
class EditTaskResult {
  const EditTaskResult({
    required this.title,
    required this.estimatedMinutes,
    required this.dueDate,
    required this.importance,
  });

  final String title;
  final int estimatedMinutes;
  final DateTime dueDate;
  final ImportanceEnum importance;
}

/// Formulário de edição de tarefa. O campo de título fica **no topo** (o teclado
/// nunca o cobre). Tempo/importância/prazo via chips (1 toque).
class EditTaskPage extends StatefulWidget {
  const EditTaskPage({super.key, required this.task, required this.today});

  final TaskEntity task;
  final DateTime today;

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  late final TextEditingController _title =
      TextEditingController(text: widget.task.title);
  late int _estimated = widget.task.estimatedMinutes ?? 30;
  late ImportanceEnum _importance = widget.task.importance ?? ImportanceEnum.min;
  late DateTime _due = widget.task.dueDate ?? widget.today;

  static const _minuteOptions = [15, 30, 60, 120];

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(EditTaskResult(
      title: title,
      estimatedMinutes: _estimated,
      dueDate: _due,
      importance: _importance,
    ));
  }

  int _daysFromToday(int days) => days;

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
                    selected: _due.difference(widget.today).inDays ==
                        _daysFromToday(entry.value),
                    onSelected: (_) => setState(() =>
                        _due = widget.today.add(Duration(days: entry.value))),
                  ),
              ],
            ),
            SizedBox(height: context.space.xxxl),
            AppPrimaryButton(label: 'Salvar', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
