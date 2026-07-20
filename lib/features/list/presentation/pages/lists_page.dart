import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_empty_state.dart';
import '../../../../core/ui/app_list_skeleton.dart';
import '../../domain/entities/task_list_entity.dart';
import '../bloc/list_manager_bloc.dart';

/// Gerência de listas (criar, renomear, excluir).
class ListsPage extends StatefulWidget {
  const ListsPage({super.key});

  @override
  State<ListsPage> createState() => _ListsPageState();
}

class _ListsPageState extends State<ListsPage> {
  final _newListController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ListManagerBloc>().add(const ListManagerStarted());
  }

  @override
  void dispose() {
    _newListController.dispose();
    super.dispose();
  }

  void _create() {
    final name = _newListController.text.trim();
    if (name.isEmpty) return;
    context.read<ListManagerBloc>().add(ListCreated(name));
    _newListController.clear();
  }

  Future<void> _rename(TaskListEntity list) async {
    final controller = TextEditingController(text: list.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renomear lista'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && mounted) {
      context
          .read<ListManagerBloc>()
          .add(ListRenamed(listId: list.id, name: name));
    }
  }

  Future<void> _delete(TaskListEntity list, List<TaskListEntity> all) async {
    final others = all.where((l) => l.id != list.id).toList();
    final bloc = context.read<ListManagerBloc>();
    final choice = await showDialog<String?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Excluir "${list.name}"'),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text('O que fazer com as tarefas desta lista?'),
          ),
          for (final o in others)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(o.id),
              child: Text('Mover para "${o.name}"'),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop('__delete_all__'),
            child: const Text('Excluir todas as tarefas'),
          ),
        ],
      ),
    );
    if (choice == null) return;
    bloc.add(ListDeleted(
      listId: list.id,
      moveToListId: choice == '__delete_all__' ? null : choice,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listas')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Criação no topo — o teclado não cobre o campo.
            Container(
              padding: EdgeInsets.all(context.space.md),
              color: context.colors.surfaceHigh,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newListController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _create(),
                      style: context.text.bodyMedium,
                      decoration: const InputDecoration(
                        hintText: 'Nova lista…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(width: context.space.sm),
                  IconButton(
                    onPressed: _create,
                    icon: Icon(Icons.add_rounded, color: context.colors.primary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocConsumer<ListManagerBloc, ListManagerState>(
                listenWhen: (_, c) => c is ListManagerError,
                listener: (context, state) {
                  if (state is ListManagerError) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(state.message)));
                  }
                },
                builder: (context, state) {
                  return switch (state) {
                    ListManagerLoading() => const AppListSkeleton(),
                    ListManagerError() => const AppEmptyState(
                        icon: Icons.folder_rounded,
                        title: 'Não foi possível carregar',
                        message: 'Tente novamente em instantes.',
                      ),
                    ListManagerLoaded(:final lists) => ListView.separated(
                        padding: EdgeInsets.all(context.space.lg),
                        itemCount: lists.length,
                        separatorBuilder: (_, _) =>
                            SizedBox(height: context.space.sm),
                        itemBuilder: (context, i) {
                          final list = lists[i];
                          return _ListRow(
                            list: list,
                            onRename: () => _rename(list),
                            onDelete: () => _delete(list, lists),
                          );
                        },
                      ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.list,
    required this.onRename,
    required this.onDelete,
  });

  final TaskListEntity list;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.space.lg,
        vertical: context.space.md,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: context.radius.lgRadius,
      ),
      child: Row(
        children: [
          Icon(
            list.isDefault ? Icons.inbox_rounded : Icons.folder_rounded,
            color: colors.primary,
            size: 22,
          ),
          SizedBox(width: context.space.md),
          Expanded(child: Text(list.name, style: context.text.titleMedium)),
          if (!list.isDefault) ...[
            IconButton(
              onPressed: onRename,
              icon: Icon(Icons.edit_rounded, color: colors.textMuted),
              tooltip: 'Renomear',
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_rounded, color: colors.textMuted),
              tooltip: 'Excluir',
            ),
          ],
        ],
      ),
    );
  }
}
