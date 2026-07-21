import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_empty_state.dart';
import '../../../../core/ui/app_list_skeleton.dart';
import '../../../../core/ui/task_timer_actions.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../appointment/presentation/bloc/agenda_bloc.dart';
import '../../../appointment/presentation/pages/agenda_page.dart';
import '../../../list/domain/entities/task_list_entity.dart';
import '../../../list/presentation/bloc/list_manager_bloc.dart';
import '../../../list/presentation/pages/lists_page.dart';
import '../../../migration/presentation/bloc/migration_bloc.dart';
import '../../../migration/presentation/pages/migration_page.dart';
import '../../../report/presentation/bloc/report_bloc.dart';
import '../../../report/presentation/pages/report_page.dart';
import '../../domain/entities/prioritized_leaf.dart';
import '../../domain/entities/task_entity.dart';
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
  bool _priorityView = true;
  TaskNode? _subtaskParent;
  String? _selectedListId;

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
      bloc.add(TaskCreated(title, listId: _selectedListId));
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

  void _toggleDone(TaskNode node, bool done) => _toggleDoneTask(node.task, done);

  void _toggleDoneTask(TaskEntity task, bool done) {
    final bloc = context.read<TaskListBloc>()
      ..add(CompleteToggled(taskId: task.id, done: done));
    if (done) {
      // Desfazer (H13): reabre a folha.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('"${task.title}" concluída'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () =>
                bloc.add(CompleteToggled(taskId: task.id, done: false)),
          ),
        ));
    }
  }

  Future<void> _confirmDelete(TaskNode node) => _confirmDeleteTask(node.task);

  Future<void> _confirmDeleteTask(TaskEntity task) async {
    final bloc = context.read<TaskListBloc>();
    final hasChildren = task.hasChildren;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir tarefa?'),
        content: Text(hasChildren
            ? 'Isso apaga "${task.title}" e todas as filhas/netas.'
            : 'Isso apaga "${task.title}".'),
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
      bloc.add(DeleteRequested(task.id));
    }
  }

  void _onMenu(String value) {
    switch (value) {
      case 'agenda':
        _push(getIt<AgendaBloc>(), const AgendaPage());
      case 'lists':
        _push(getIt<ListManagerBloc>(), const ListsPage());
      case 'report':
        _push(getIt<ReportBloc>(), const ReportPage());
      case 'migration':
        _push(getIt<MigrationBloc>(), const MigrationPage());
      case 'logout':
        context.read<AuthBloc>().add(const AuthSignOutRequested());
    }
  }

  void _push<B extends StateStreamableSource<Object?>>(B bloc, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider<B>(create: (_) => bloc, child: page),
      ),
    );
  }

  Future<void> _editTask(TaskNode node) => _editTaskEntity(node.task);

  Future<void> _editTaskEntity(TaskEntity task) async {
    final bloc = context.read<TaskListBloc>();
    final result = await Navigator.of(context).push<EditTaskResult>(
      MaterialPageRoute(
        builder: (_) => EditTaskPage(task: task, today: DateTime.now()),
      ),
    );
    if (result != null) {
      bloc.add(EditRequested(
        taskId: task.id,
        title: result.title,
        estimatedMinutes: result.estimatedMinutes,
        dueDate: result.dueDate,
        importance: result.importance,
      ));
    }
  }

  Future<void> _moveTask(TaskNode node) {
    // Candidatos: todos os nós, menos o próprio e seus descendentes.
    final excluded = <String>{};
    void collect(TaskNode n) {
      excluded.add(n.task.id);
      n.children.forEach(collect);
    }

    collect(node);
    return _moveTaskExcluding(node.task.id, excluded);
  }

  /// Mover uma folha da visão por prioridade: como folha não tem descendentes,
  /// basta excluir a própria da lista de destinos.
  Future<void> _moveTaskEntity(TaskEntity task) =>
      _moveTaskExcluding(task.id, {task.id});

  Future<void> _moveTaskExcluding(String taskId, Set<String> excluded) async {
    final bloc = context.read<TaskListBloc>();
    final state = bloc.state;
    if (state is! TaskListLoaded) return;

    final candidates = _moveCandidates(state.roots, excluded);

    final chosen = await showDialog<String?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Mover para'),
        children: [
          ListTile(
            leading: const Icon(Icons.home_rounded),
            title: const Text('Tornar tarefa mãe (raiz)'),
            onTap: () => Navigator.of(ctx).pop('__root__'),
          ),
          for (final c in candidates)
            ListTile(
              title: Text(c.node.task.title),
              subtitle: Text(c.path),
              onTap: () => Navigator.of(ctx).pop(c.node.task.id),
            ),
          ListTile(
            title: const Text('Cancelar'),
            onTap: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
    if (chosen == null) return;
    bloc.add(MoveRequested(
      taskId: taskId,
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

  /// Candidatos de destino para "Mover", cada um com o breadcrumb dos ancestrais
  /// e o nível (mãe/filha) — desambigua títulos parecidos na hierarquia.
  List<({TaskNode node, String path})> _moveCandidates(
    List<TaskNode> roots,
    Set<String> excluded,
  ) {
    final out = <({TaskNode node, String path})>[];
    void visit(TaskNode n, List<String> ancestors) {
      if (!excluded.contains(n.task.id) && !n.isMaxLevel) {
        final breadcrumb = ancestors.isEmpty
            ? _levelLabel(n.level)
            : '${ancestors.join(' › ')} · ${_levelLabel(n.level)}';
        out.add((node: n, path: breadcrumb));
      }
      for (final c in n.children) {
        visit(c, [...ancestors, n.task.title]);
      }
    }

    for (final r in roots) {
      visit(r, const []);
    }
    return out;
  }

  String _levelLabel(int level) => switch (level) {
        0 => 'tarefa mãe',
        1 => 'tarefa filha',
        _ => 'tarefa neta',
      };

  @override
  Widget build(BuildContext context) {
    final parent = _subtaskParent;
    // Listas do usuário (só para o seletor da criação rápida de tarefa raiz).
    final lists = context.select<TaskListBloc, List<TaskListEntity>>((b) {
      final s = b.state;
      return s is TaskListLoaded ? s.lists : const [];
    });
    _selectedListId ??= lists.where((l) => l.isDefault).isNotEmpty
        ? lists.firstWhere((l) => l.isDefault).id
        : (lists.isNotEmpty ? lists.first.id : null);
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: _onMenu,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'agenda', child: Text('Agenda')),
              PopupMenuItem(value: 'lists', child: Text('Listas')),
              PopupMenuItem(value: 'report', child: Text('Relatório')),
              PopupMenuItem(value: 'migration', child: Text('Pendências')),
              PopupMenuItem(value: 'logout', child: Text('Sair')),
            ],
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
                // Seletor de lista só na criação de tarefa raiz.
                lists: parent == null ? lists : const [],
                selectedListId: _selectedListId,
                onListSelected: (id) => setState(() => _selectedListId = id),
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
                              onAddTime: (leaf, minutes) => _addTime(
                                TaskNode(task: leaf.task, level: 0),
                                minutes,
                              ),
                              onToggleDone: (leaf, done) =>
                                  _toggleDoneTask(leaf.task, done),
                              onEdit: (leaf) => _editTaskEntity(leaf.task),
                              onMove: (leaf) => _moveTaskEntity(leaf.task),
                              onDelete: (leaf) => _confirmDeleteTask(leaf.task),
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
    required this.onAddTime,
    required this.onToggleDone,
    required this.onEdit,
    required this.onMove,
    required this.onDelete,
  });

  final List<PrioritizedLeaf> leaves;
  final String? activeTaskId;
  final void Function(PrioritizedLeaf leaf, bool start) onToggleTimer;
  final void Function(PrioritizedLeaf leaf, int minutes) onAddTime;
  final void Function(PrioritizedLeaf leaf, bool done) onToggleDone;
  final void Function(PrioritizedLeaf leaf) onEdit;
  final void Function(PrioritizedLeaf leaf) onMove;
  final void Function(PrioritizedLeaf leaf) onDelete;

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
          onAddTime: () => onAddTime(leaf, TaskTimerActions.quickMinutes),
          onToggleDone: () => onToggleDone(leaf, !leaf.task.isDone),
          onEdit: () => onEdit(leaf),
          onMove: () => onMove(leaf),
          onDelete: () => onDelete(leaf),
        );
      },
    );
  }
}
