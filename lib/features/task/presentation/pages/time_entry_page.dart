import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_empty_state.dart';
import '../../../../core/ui/app_list_skeleton.dart';
import '../../../../core/utils/formatters/date_formatter.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/time_entry_entity.dart';
import '../bloc/time_entry_bloc.dart';
import '../widgets/time_entry_tile.dart';

/// Tela "Registros de tempo" de uma folha: CRUD dos lançamentos que compõem o
/// tempo gasto. Editar aqui ajusta o acumulado da folha por delta (no UseCase).
class TimeEntryPage extends StatefulWidget {
  const TimeEntryPage({super.key, required this.leaf});

  final TaskEntity leaf;

  @override
  State<TimeEntryPage> createState() => _TimeEntryPageState();
}

class _TimeEntryPageState extends State<TimeEntryPage> {
  static const _minuteOptions = [15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    context.read<TimeEntryBloc>().add(TimeEntryStarted(
          targetId: widget.leaf.id,
          listId: widget.leaf.listId,
        ));
  }

  Future<void> _add() async {
    final bloc = context.read<TimeEntryBloc>();
    final result = await _showEditor(initialMinutes: 30, initialDate: null);
    if (result == null) return;
    bloc.add(TimeEntryAdded(
      minutes: result.minutes,
      occurredAt: result.occurredAt,
    ));
  }

  Future<void> _edit(TimeEntryEntity entry) async {
    final bloc = context.read<TimeEntryBloc>();
    final result = await _showEditor(
      initialMinutes: entry.minutes,
      initialDate: entry.occurredAt,
    );
    if (result == null) return;
    bloc.add(TimeEntryEdited(
      original: entry,
      minutes: result.minutes,
      occurredAt: result.occurredAt,
    ));
  }

  void _delete(TimeEntryEntity entry) {
    final bloc = context.read<TimeEntryBloc>()..add(TimeEntryDeleted(entry));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('Registro excluído'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => bloc.add(const TimeEntryUndoRequested()),
        ),
      ));
  }

  /// Bottom sheet de edição de um registro: duração (chips) + data (calendário).
  Future<({int minutes, DateTime occurredAt})?> _showEditor({
    required int initialMinutes,
    required DateTime? initialDate,
  }) {
    final now = DateTime.now();
    var minutes = initialMinutes;
    var date = initialDate ?? now;
    return showModalBottomSheet<({int minutes, DateTime occurredAt})>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheet) {
            final options = <int>{..._minuteOptions, minutes}.toList()..sort();
            return Padding(
              padding: EdgeInsets.only(
                left: sheetContext.space.lg,
                right: sheetContext.space.lg,
                top: sheetContext.space.lg,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
                    sheetContext.space.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Duração', style: sheetContext.text.labelLarge),
                  SizedBox(height: sheetContext.space.sm),
                  Wrap(
                    spacing: sheetContext.space.sm,
                    children: [
                      for (final m in options)
                        ChoiceChip(
                          label: Text('$m min'),
                          selected: minutes == m,
                          onSelected: (_) => setSheet(() => minutes = m),
                        ),
                    ],
                  ),
                  SizedBox(height: sheetContext.space.xl),
                  Text('Data', style: sheetContext.text.labelLarge),
                  SizedBox(height: sheetContext.space.sm),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text(DateFormatter.full(date)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: sheetContext,
                        initialDate: date,
                        firstDate: DateTime(now.year - 5),
                        lastDate: DateTime(now.year + 5),
                      );
                      if (picked != null) {
                        setSheet(() => date = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              date.hour,
                              date.minute,
                            ));
                      }
                    },
                  ),
                  SizedBox(height: sheetContext.space.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(sheetContext)
                          .pop((minutes: minutes, occurredAt: date)),
                      child: const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('Tempo gasto')),
      body: SafeArea(
        child: BlocConsumer<TimeEntryBloc, TimeEntryState>(
          listenWhen: (_, curr) => curr is TimeEntryError,
          listener: (context, state) {
            if (state is TimeEntryError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            return switch (state) {
              TimeEntryLoading() => const AppListSkeleton(),
              TimeEntryEmpty() => const AppEmptyState(
                  icon: Icons.schedule_rounded,
                  title: 'Nenhum registro ainda',
                  message: 'Toque em + para lançar um tempo gasto.',
                ),
              TimeEntryLoaded(:final entries) => ListView.separated(
                  padding: EdgeInsets.all(context.space.lg),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) =>
                      SizedBox(height: context.space.sm),
                  itemBuilder: (context, i) => TimeEntryTile(
                    entry: entries[i],
                    today: today,
                    onEdit: () => _edit(entries[i]),
                    onDelete: () => _delete(entries[i]),
                  ),
                ),
              TimeEntryError() => const AppEmptyState(
                  icon: Icons.schedule_rounded,
                  title: 'Nenhum registro ainda',
                  message: 'Toque em + para lançar um tempo gasto.',
                ),
            };
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
