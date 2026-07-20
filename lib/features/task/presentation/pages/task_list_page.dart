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
  });

  final List<TaskNode> nodes;
  final String? activeTaskId;
  final void Function(TaskNode parent) onAddSubtask;
  final void Function(TaskNode node, bool start) onToggleTimer;
  final void Function(TaskNode node, int minutes) onAddTime;

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
