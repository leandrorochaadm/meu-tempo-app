import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_empty_state.dart';
import '../../../../core/ui/app_list_skeleton.dart';
import '../../../../core/ui/app_primary_button.dart';
import '../../../../core/ui/app_undo_snackbar.dart';
import '../../../list/domain/entities/task_list_entity.dart';
import '../../domain/entities/recurring_task_entity.dart';
import '../../domain/usecases/update_recurring_task_use_case.dart';
import '../bloc/recurring_task_bloc.dart';
import '../widgets/recurring_task_card_widget.dart';
import 'edit_recurring_task_page.dart';

/// Tela "Tarefas recorrentes" (H15): lista os modelos, cria, edita, exclui
/// arrastando (com desfazer) e adiciona o modelo na lista de hoje. O
/// `RecurringTasksStarted` é disparado no `BlocProvider` da rota.
class RecurringTasksPage extends StatelessWidget {
  const RecurringTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecurringTaskBloc, RecurringTaskState>(
      buildWhen: (_, c) => c is! RecurringTaskEffect,
      listenWhen: (_, c) => c is RecurringTaskEffect,
      listener: _onEffect,
      builder: (context, state) {
        final bloc = context.read<RecurringTaskBloc>();
        // O ScaffoldMessenger é do app: sem isto o "Desfazer" iria para a home,
        // onde o Bloc da rota já está fechado.
        return PopScope(
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          child: Scaffold(
            appBar: AppBar(title: const Text('Tarefas recorrentes')),
            body: SafeArea(
              top: false,
              child: switch (state) {
                RecurringTaskLoading() => const AppListSkeleton(),
                RecurringTaskLoaded(:final items, :final lists)
                    when items.isEmpty =>
                  AppEmptyState(
                    icon: Icons.repeat_rounded,
                    title: 'Nenhuma tarefa recorrente',
                    message:
                        'Crie uma para não precisar digitar a mesma tarefa sempre.',
                    action: AppPrimaryButton(
                      label: 'Nova tarefa recorrente',
                      icon: Icons.add_rounded,
                      onPressed: () => _openForm(context, lists: lists),
                    ),
                  ),
                RecurringTaskLoaded(:final items, :final lists) =>
                  _TemplatesList(
                    items: items,
                    lists: lists,
                    onEdit: (t) =>
                        _openForm(context, lists: lists, template: t),
                  ),
                RecurringTaskError(:final message) => AppEmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Não deu para carregar',
                  message: message,
                  action: TextButton(
                    onPressed: () => bloc.add(const RecurringTasksStarted()),
                    child: const Text('Tentar de novo'),
                  ),
                ),
                // Nunca pintado (buildWhen); só fecha o switch exaustivo.
                RecurringTaskEffect() => const SizedBox.shrink(),
              },
            ),
            floatingActionButton: switch (state) {
              RecurringTaskLoaded(:final items, :final lists)
                  when items.isNotEmpty =>
                FloatingActionButton.extended(
                  onPressed: () => _openForm(context, lists: lists),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nova'),
                ),
              _ => null,
            },
          ),
        );
      },
    );
  }

  void _onEffect(BuildContext context, RecurringTaskState state) {
    if (state is! RecurringTaskEffect) return;
    final bloc = context.read<RecurringTaskBloc>();
    switch (state) {
      case RecurringTaskAddedTodayDone():
        _showMessage(context, 'Tarefa adicionada para hoje');
      case RecurringTaskDeletedDone(:final template):
        AppUndoSnackBar.show(
          context,
          message: 'Tarefa recorrente excluída',
          onUndo: () => bloc.add(RecurringTaskRestored(template)),
        );
      case RecurringTaskConfirmRequested(:final template):
        _confirmAddToday(context, template);
      case RecurringTaskActionFailed(:final message):
        _showMessage(context, message);
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Abre o formulário (criar se [template] é nulo) e despacha o evento com o
  /// resultado. `Navigator.push(MaterialPageRoute)` é exceção consciente ao
  /// `navigation.md`, igual à agenda (`agenda_page.dart:34`): sub-tela de
  /// formulário, sem URL própria, que devolve dado para quem abriu.
  Future<void> _openForm(
    BuildContext context, {
    required List<TaskListEntity> lists,
    RecurringTaskEntity? template,
  }) async {
    final bloc = context.read<RecurringTaskBloc>();
    final result = await Navigator.of(context).push<RecurringTaskFormResult>(
      MaterialPageRoute(
        builder: (_) => EditRecurringTaskPage(template: template, lists: lists),
      ),
    );
    if (result == null || !context.mounted) return;
    if (template == null) {
      bloc.add(
        RecurringTaskCreated(
          title: result.title,
          listId: result.listId,
          estimatedMinutes: result.estimatedMinutes,
          importance: result.importance,
          weekdays: result.weekdays,
        ),
      );
    } else {
      bloc.add(
        RecurringTaskEdited(
          UpdateRecurringTaskParams(
            original: template,
            title: result.title,
            listId: result.listId,
            estimatedMinutes: result.estimatedMinutes,
            importance: result.importance,
            weekdays: result.weekdays,
          ),
        ),
      );
    }
  }

  /// Diálogo do R4 (H15): só chega aqui para modelo com dias e tarefa pendente.
  Future<void> _confirmAddToday(
    BuildContext context,
    RecurringTaskEntity template,
  ) async {
    final bloc = context.read<RecurringTaskBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Text(
          'Essa tarefa já está na sua lista e ainda não foi feita. Criar mesmo assim?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      bloc.add(RecurringTaskAddedToday(template, confirmed: true));
    }
  }
}

class _TemplatesList extends StatelessWidget {
  const _TemplatesList({
    required this.items,
    required this.lists,
    required this.onEdit,
  });

  final List<RecurringTaskEntity> items;
  final List<TaskListEntity> lists;
  final ValueChanged<RecurringTaskEntity> onEdit;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RecurringTaskBloc>();
    final listNames = <String, String>{for (final l in lists) l.id: l.name};
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        context.space.lg,
        context.space.lg,
        context.space.lg,
        context.space.xxxl * 2,
      ),
      itemCount: items.length,
      separatorBuilder: (_, _) => SizedBox(height: context.space.sm),
      itemBuilder: (context, index) {
        final t = items[index];
        return Dismissible(
          key: ValueKey(t.id),
          direction: DismissDirection.endToStart,
          background: const _DeleteBackground(),
          onDismissed: (_) => bloc.add(RecurringTaskDeleted(t)),
          child: RecurringTaskCardWidget(
            template: t,
            listName: listNames[t.listId],
            onTap: () => onEdit(t),
            onAddToday: () => bloc.add(RecurringTaskAddedToday(t)),
          ),
        );
      },
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: context.space.lg),
      decoration: BoxDecoration(
        color: context.colors.danger,
        borderRadius: context.radius.lgRadius,
      ),
      child: Icon(Icons.delete_rounded, color: context.colors.onPrimary),
    );
  }
}
