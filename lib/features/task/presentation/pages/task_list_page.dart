import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_empty_state.dart';
import '../../../../core/ui/app_list_skeleton.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/prioritized_leaf.dart';
import '../../domain/entities/task_node.dart';
import '../bloc/task_list_bloc.dart';
import '../widgets/prioritized_leaf_tile.dart';
import '../widgets/quick_add_task_widget.dart';
import '../widgets/task_node_tile.dart';
import 'edit_task_page.dart';

/// Listagem hierárquica de tarefas + criação rápida (barra no topo).
class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  bool _quickAddVisible = false;
  bool _priorityView = false;
  TaskNode? _subtaskParent;

  @override
  void initState() {
    super.initState();
    context.read<TaskListBloc>().add(const TaskListStarted());
  }

  void _startSubtask(TaskNode parent) {
    setState(() {
      _subtaskParent = parent;
      _quickAddVisible = true;
    });
  }

  void _submit(String title) {
    final bloc = context.read<TaskListBloc>();
    final parent = _subtaskParent;
    if (parent != null) {
      bloc.add(SubtaskRequested(
        parentId: parent.task.id,
        parentLevel: parent.level,
        listId: parent.task.listId,
        title: title,
      ));
    } else {
      bloc.add(TaskCreated(title));
    }
  }

  void _toggleTimer(TaskNode node, bool start) {
    context.read<TaskListBloc>().add(
          start
              ? TimerStartRequested(taskId: node.task.id, isLeaf: node.isLeaf)
              : const TimerStopRequested(),
        );
  }

  void _addTime(TaskNode node, int minutes) {
    context.read<TaskListBloc>().add(
          ManualTimeRequested(
            taskId: node.task.id,
            isLeaf: node.isLeaf,
            minutes: minutes,
          ),
        );
  }

  void _toggleDone(TaskNode node, bool done) {
    context
        .read<TaskListBloc>()
        .add(CompleteToggled(taskId: node.task.id, done: done));
  }

  Future<void> _confirmDelete(TaskNode node) async {
    final bloc = context.read<TaskListBloc>();
    final hasChildren = node.task.hasChildren;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir tarefa?'),
        content: Text(hasChildren
            ? 'Isso apaga "${node.task.title}" e todas as filhas/netas.'
            : 'Isso apaga "${node.task.title}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      bloc.add(DeleteRequested(node.task.id));
    }
  }

  Future<void> _editTask(TaskNode node) async {
    final bloc = context.read<TaskListBloc>();
    final result = await Navigator.of(context).push<EditTaskResult>(
      MaterialPageRoute(
        builder: (_) => EditTaskPage(task: node.task, today: DateTime.now()),
      ),
    );
    if (result != null) {
      bloc.add(EditRequested(
        taskId: node.task.id,
        title: result.title,
        estimatedMinutes: result.estimatedMinutes,
        dueDate: result.dueDate,
        importance: result.importance,
      ));
    }
  }

  Future<void> _moveTask(TaskNode node) async {
    final bloc = context.read<TaskListBloc>();
    final state = bloc.state;
    if (state is! TaskListLoaded) return;

    // Candidatos: todos os nós, menos o próprio e seus descendentes.
    final excluded = <String>{};
    void collect(TaskNode n) {
      excluded.add(n.task.id);
      n.children.forEach(collect);
    }

    collect(node);
    final candidates = _flatten(state.roots)
        .where((n) => !excluded.contains(n.task.id) && !n.isMaxLevel)
        .toList();

    final chosen = await showDialog<String?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Mover para'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop('__root__'),
            child: const Text('Tornar tarefa mãe (raiz)'),
          ),
          for (final c in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(c.task.id),
              child: Text(c.task.title),
            ),
        ],
      ),
    );
    if (chosen == null) return;
    bloc.add(MoveRequested(
      taskId: node.task.id,
      newParentId: chosen == '__root__' ? null : chosen,
    ));
  }

  void _toggleLeafTimer(PrioritizedLeaf leaf, bool start) {
    context.read<TaskListBloc>().add(
          start
              ? TimerStartRequested(taskId: leaf.task.id, isLeaf: true)
              : const TimerStopRequested(),
        );
  }

  /// Achata a árvore em ordem (pré-ordem) preservando a indentação por nível.
  List<TaskNode> _flatten(List<TaskNode> roots) {
    final out = <TaskNode>[];
    void visit(TaskNode n) {
      out.add(n);
      for (final c in n.children) {
        visit(c);
      }
    }

    for (final r in roots) {
      visit(r);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final parent = _subtaskParent;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Tempo'),
        actions: [
          IconButton(
            icon: Icon(_priorityView
                ? Icons.account_tree_rounded
                : Icons.sort_rounded),
            tooltip: _priorityView ? 'Ver hierarquia' : 'Ver por prioridade',
            onPressed: () => setState(() => _priorityView = !_priorityView),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sair',
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthSignOutRequested()),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_quickAddVisible)
              QuickAddTaskWidget(
                hint: parent == null
                    ? 'Nova tarefa…'
                    : 'Subtarefa de "${parent.task.title}"…',
                onSubmit: _submit,
              ),
            Expanded(
              child: BlocConsumer<TaskListBloc, TaskListState>(
                listenWhen: (_, curr) => curr is TaskListError,
                listener: (context, state) {
                  if (state is TaskListError) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(state.message)));
                  }
                },
                builder: (context, state) {
                  return switch (state) {
                    TaskListLoading() => const AppListSkeleton(),
                    TaskListEmpty() => const AppEmptyState(
                        icon: Icons.checklist_rounded,
                        title: 'Sua lista está vazia',
                        message: 'Toque em + para criar sua primeira tarefa.',
                      ),
                    TaskListLoaded(
                      :final roots,
                      :final prioritized,
                      :final activeTaskId,
                    ) =>
                      _priorityView
                          ? _PriorityList(
                              leaves: prioritized,
                              activeTaskId: activeTaskId,
                              onToggleTimer: _toggleLeafTimer,
                            )
                          : _TaskTree(
                              nodes: _flatten(roots),
                              activeTaskId: activeTaskId,
                              onAddSubtask: _startSubtask,
                              onToggleTimer: _toggleTimer,
                              onAddTime: _addTime,
                              onToggleDone: _toggleDone,
                              onDelete: _confirmDelete,
                              onEdit: _editTask,
                              onMove: _moveTask,
                            ),
                    TaskListError() => const AppEmptyState(
                        icon: Icons.checklist_rounded,
                        title: 'Sua lista está vazia',
                        message: 'Toque em + para criar sua primeira tarefa.',
                      ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() {
          _quickAddVisible = !_quickAddVisible;
          _subtaskParent = null;
        }),
        child: Icon(_quickAddVisible ? Icons.close_rounded : Icons.add_rounded),
      ),
    );
  }
}

class _TaskTree extends StatelessWidget {
  const _TaskTree({
    required this.nodes,
    required this.activeTaskId,
    required this.onAddSubtask,
    required this.onToggleTimer,
    required this.onAddTime,
    required this.onToggleDone,
    required this.onDelete,
    required this.onEdit,
    required this.onMove,
  });

  final List<TaskNode> nodes;
  final String? activeTaskId;
  final void Function(TaskNode parent) onAddSubtask;
  final void Function(TaskNode node, bool start) onToggleTimer;
  final void Function(TaskNode node, int minutes) onAddTime;
  final void Function(TaskNode node, bool done) onToggleDone;
  final void Function(TaskNode node) onDelete;
  final void Function(TaskNode node) onEdit;
  final void Function(TaskNode node) onMove;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(context.space.lg),
      itemCount: nodes.length,
      separatorBuilder: (_, _) => SizedBox(height: context.space.sm),
      itemBuilder: (context, i) => TaskNodeTile(
        node: nodes[i],
        isActive: nodes[i].task.id == activeTaskId,
        onAddSubtask: onAddSubtask,
        onToggleTimer: onToggleTimer,
        onAddTime: onAddTime,
        onToggleDone: onToggleDone,
        onDelete: onDelete,
        onEdit: onEdit,
        onMove: onMove,
      ),
    );
  }
}

class _PriorityList extends StatelessWidget {
  const _PriorityList({
    required this.leaves,
    required this.activeTaskId,
    required this.onToggleTimer,
  });

  final List<PrioritizedLeaf> leaves;
  final String? activeTaskId;
  final void Function(PrioritizedLeaf leaf, bool start) onToggleTimer;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return ListView.separated(
      padding: EdgeInsets.all(context.space.lg),
      itemCount: leaves.length,
      separatorBuilder: (_, _) => SizedBox(height: context.space.sm),
      itemBuilder: (context, i) {
        final leaf = leaves[i];
        final isActive = leaf.task.id == activeTaskId;
        return PrioritizedLeafTile(
          leaf: leaf,
          isActive: isActive,
          today: today,
          onToggleTimer: () => onToggleTimer(leaf, !isActive),
        );
      },
    );
  }
}
