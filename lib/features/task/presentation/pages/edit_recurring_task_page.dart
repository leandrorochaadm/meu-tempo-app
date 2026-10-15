import 'package:flutter/material.dart';

import '../../../../core/constants/app_defaults.dart';
import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_primary_button.dart';
import '../../../../core/utils/formatters/duration_formatter.dart';
import '../../../list/domain/entities/task_list_entity.dart';
import '../../domain/entities/importance_enum.dart';
import '../../domain/entities/recurring_task_entity.dart';
import '../../domain/entities/weekday_enum.dart';
import '../widgets/importance_presentation.dart';
import '../widgets/weekday_selector_widget.dart';

/// Dados do formulário devolvidos via `Navigator.pop`. A página da lista
/// converte em `RecurringTaskCreated`/`RecurringTaskEdited`.
class RecurringTaskFormResult {
  const RecurringTaskFormResult({
    required this.title,
    required this.listId,
    required this.estimatedMinutes,
    required this.importance,
    required this.weekdays,
  });

  final String title;
  final String listId;
  final int estimatedMinutes;
  final ImportanceEnum importance;
  final Set<WeekdayEnum> weekdays;
}

/// Formulário único de criar/editar um modelo de tarefa recorrente.
///
/// Aberta por `Navigator.push(MaterialPageRoute)` e devolve o resultado pelo
/// `pop` — exceção consciente ao `navigation.md`, igual à `AddAppointmentPage`
/// em `agenda_page.dart:34`: é sub-tela de formulário, sem URL própria, e
/// precisa devolver dado para quem abriu.
class EditRecurringTaskPage extends StatefulWidget {
  const EditRecurringTaskPage({super.key, this.template, required this.lists});

  /// `null` = criar.
  final RecurringTaskEntity? template;
  final List<TaskListEntity> lists;

  @override
  State<EditRecurringTaskPage> createState() => _EditRecurringTaskPageState();
}

class _EditRecurringTaskPageState extends State<EditRecurringTaskPage> {
  late final TextEditingController _title = TextEditingController(
    text: widget.template?.title ?? '',
  );
  late String? _listId = _initialListId();
  late int _estimated =
      widget.template?.estimatedMinutes ?? AppDefaults.defaultEstimatedMinutes;
  late ImportanceEnum _importance =
      widget.template?.importance ?? ImportanceEnum.min;
  late Set<WeekdayEnum> _weekdays = {...?widget.template?.weekdays};

  String? _initialListId() {
    final template = widget.template;
    if (template != null) return template.listId;
    if (widget.lists.isEmpty) return null;
    return widget.lists
        .firstWhere((l) => l.isDefault, orElse: () => widget.lists.first)
        .id;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(
      RecurringTaskFormResult(
        title: title,
        listId: _listId!,
        estimatedMinutes: _estimated,
        importance: _importance,
        weekdays: Set.unmodifiable(_weekdays),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCreating = widget.template == null;
    final minuteOptions = <int>{
      ...AppDefaults.estimatedMinuteOptions,
      _estimated,
    }.toList()..sort();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isCreating ? 'Nova tarefa recorrente' : 'Editar tarefa recorrente',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(context.space.lg),
          children: [
            TextField(
              controller: _title,
              autofocus: isCreating,
              style: context.text.bodyMedium,
              decoration: const InputDecoration(labelText: 'Título'),
              textCapitalization: TextCapitalization.sentences,
            ),
            SizedBox(height: context.space.xl),
            if (widget.lists.isNotEmpty) ...[
              Text('Lista', style: context.text.labelLarge),
              SizedBox(height: context.space.sm),
              Wrap(
                spacing: context.space.sm,
                children: [
                  for (final list in widget.lists)
                    ChoiceChip(
                      label: Text(list.name),
                      selected: _listId == list.id,
                      onSelected: (_) => setState(() => _listId = list.id),
                    ),
                ],
              ),
              SizedBox(height: context.space.xl),
            ],
            Text('Tempo estimado', style: context.text.labelLarge),
            SizedBox(height: context.space.sm),
            Wrap(
              spacing: context.space.sm,
              children: [
                for (final m in minuteOptions)
                  ChoiceChip(
                    label: Text(DurationFormatter.hm(m)),
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
                    label: Text(imp.label),
                    selected: _importance == imp,
                    onSelected: (_) => setState(() => _importance = imp),
                  ),
              ],
            ),
            SizedBox(height: context.space.xl),
            Text('Repetir', style: context.text.labelLarge),
            SizedBox(height: context.space.sm),
            WeekdaySelectorWidget(
              selected: _weekdays,
              onChanged: (d) => setState(() => _weekdays = d),
            ),
            SizedBox(height: context.space.xxxl),
            AppPrimaryButton(
              label: 'Salvar',
              onPressed: _listId == null ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
