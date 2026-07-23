import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_empty_state.dart';
import '../../../../core/ui/app_list_skeleton.dart';
import '../../../../core/ui/app_undo_snackbar.dart';
import '../../../../core/ui/task_timer_actions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../list/domain/entities/task_list_entity.dart';
import '../../domain/entities/prioritized_leaf.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_node.dart';
import '../../domain/services/ancestry_label_builder.dart';
import '../bloc/task_list_bloc.dart';
import '../widgets/hide_done_chip.dart';
import '../widgets/list_filter_bar.dart';
import '../widgets/prioritized_leaf_tile.dart';
import '../widgets/quick_add_task_widget.dart';
import '../widgets/task_node_tile.dart';
import '../widgets/task_parent_picker.dart';
import 'edit_task_args.dart';
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
      bloc.add(
        SubtaskRequested(
          parentId: parent.task.id,
          parentLevel: parent.level,
          listId: parent.task.listId,
          title: title,
        ),
      );
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

  void _toggleDone(TaskNode node, bool done) =>
      _toggleDoneTask(node.task, done);

  void _toggleDoneTask(TaskEntity task, bool done) {
    final bloc = context.read<TaskListBloc>()
      ..add(CompleteToggled(taskId: task.id, done: done));
    if (done) {
      // Desfazer (H13): reabre a folha.
      AppUndoSnackBar.show(
        context,
        message: '"${task.title}" concluída',
        onUndo: () => bloc.add(CompleteToggled(taskId: task.id, done: false)),
      );
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
        content: Text(
          hasChildren
              ? 'Isso apaga "${task.title}" e todas as filhas/netas.'
              : 'Isso apaga "${task.title}".',
        ),
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
      if (!mounted) return;
      AppUndoSnackBar.show(
        context,
        message: '"${task.title}" excluída',
        onUndo: () => bloc.add(const TaskDeletionUndone()),
      );
    }
  }

  void _onMenu(String value) {
    switch (value) {
      case 'agenda':
        context.push(Routes.agenda);
      case 'lists':
        context.push(Routes.lists);
      case 'report':
        context.push(Routes.report);
      case 'migration':
        context.push(Routes.migration);
      case 'settings':
        context.push(Routes.settings);
      case 'logout':
        context.read<AuthBloc>().add(const AuthSignOutRequested());
    }
  }

  Future<void> _editTask(TaskNode node) => _editTaskEntity(node.task);

  Future<void> _editTaskEntity(TaskEntity task) async {
    final bloc = context.read<TaskListBloc>();
    final state = bloc.state;
    if (state is! TaskListLoaded) return;

    // Candidatos a mãe: exclui a própria e seus descendentes (evita ciclo).
    final excluded = _excludedFor(task.id, state.roots);
    final candidates = _moveCandidates(state.roots, excluded)
        .map(
          (c) => ParentCandidate(
            id: c.node.task.id,
            title: c.node.task.title,
            path: c.path,
          ),
        )
        .toList();

    // Breadcrumb da mãe atual (regra de ancestralidade vive no domínio).
    final byId = _allTasksById(state.roots);
    final currentParentLabel = AncestryLabelBuilder.of(task, byId);

    final args = EditTaskArgs(
      task: task,
      lists: state.lists,
      parentCandidates: candidates,
      currentParentLabel: currentParentLabel,
    );

    final result = await context.push<EditTaskResult>(
      Routes.editTask,
      extra: args,
    );
    if (result == null) return;
    bloc.add(
      EditRequested(
        taskId: task.id,
        title: result.title,
        estimatedMinutes: result.estimatedMinutes,
        dueDate: result.dueDate,
        importance: result.importance,
        listId: result.listId,
        newParentId: result.newParentId,
        parentChanged: result.parentChanged,
        isDone: result.isDone,
        doneChanged: result.doneChanged,
      ),
    );
  }

  /// Conjunto a excluir dos candidatos a mãe: a própria tarefa e todos os seus
  /// descendentes (uma tarefa não pode virar filha de si mesma/de uma neta).
  Set<String> _excludedFor(String taskId, List<TaskNode> roots) {
    final excluded = <String>{};
    void collect(TaskNode n) {
      excluded.add(n.task.id);
      n.children.forEach(collect);
    }

    TaskNode? find(List<TaskNode> nodes) {
      for (final n in nodes) {
        if (n.task.id == taskId) return n;
        final hit = find(n.children);
        if (hit != null) return hit;
      }
      return null;
    }

    final node = find(roots);
    if (node != null) {
      collect(node);
    } else {
      excluded.add(taskId);
    }
    return excluded;
  }

  /// Índice `id → TaskEntity` de toda a árvore (para o breadcrumb da mãe atual).
  Map<String, TaskEntity> _allTasksById(List<TaskNode> roots) {
    final byId = <String, TaskEntity>{};
    void visit(TaskNode n) {
      byId[n.task.id] = n.task;
      n.children.forEach(visit);
    }

    roots.forEach(visit);
    return byId;
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

    final candidates = _moveCandidates(state.roots, excluded)
        .map(
          (c) => ParentCandidate(
            id: c.node.task.id,
            title: c.node.task.title,
            path: c.path,
          ),
        )
        .toList();

    final chosen = await showTaskParentPicker(context, candidates);
    if (chosen == null) return;
    bloc.add(
      MoveRequested(
        taskId: taskId,
        newParentId: chosen == kMakeRootSentinel ? null : chosen,
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
            icon: Icon(
              _priorityView ? Icons.account_tree_rounded : Icons.sort_rounded,
            ),
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
              PopupMenuItem(value: 'settings', child: Text('Configurações')),
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
                      :final activeTimerStartedAt,
                      :final lists,
                      :final selectedListId,
                      :final hideDone,
                    ) =>
                      Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              context.space.lg,
                              context.space.md,
                              context.space.lg,
                              0,
                            ),
                            child: Wrap(
                              spacing: context.space.sm,
                              runSpacing: context.space.sm,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ListFilterBar(
                                  lists: lists,
                                  selectedListId: selectedListId,
                                  onSelected: (id) => context
                                      .read<TaskListBloc>()
                                      .add(ListFilterChanged(id)),
                                ),
                                HideDoneChip(
                                  hideDone: hideDone,
                                  onChanged: (hide) => context
                                      .read<TaskListBloc>()
                                      .add(HideDoneToggled(hide)),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child:
                                (roots.isEmpty && prioritized.isEmpty)
                                // Lista filtrada tem prioridade na mensagem; se não
                                // há filtro de lista mas as concluídas estão ocultas,
                                // explica o filtro de concluídas.
                                ? (selectedListId != null
                                    ? const AppEmptyState(
                                        icon: Icons.filter_list_off_rounded,
                                        title: 'Nenhuma tarefa nesta lista',
                                        message:
                                            'Crie uma tarefa acima ou '
                                            'troque de lista no filtro.',
                                      )
                                    : const AppEmptyState(
                                        icon: Icons.done_all_rounded,
                                        title: 'Nada pendente por aqui',
                                        message:
                                            'As tarefas concluídas estão '
                                            'ocultas. Toque em "Mostrar '
                                            'concluídas" para vê-las.',
                                      ))
                                : _priorityView
                                ? _PriorityList(
                                    leaves: prioritized,
                                    activeTaskId: activeTaskId,
                                    activeStartedAt: activeTimerStartedAt,
                                    onToggleTimer: _toggleLeafTimer,
                                    onAddTime: (leaf, minutes) => _addTime(
                                      TaskNode(task: leaf.task, level: 0),
                                      minutes,
                                    ),
                                    onToggleDone: (leaf, done) =>
                                        _toggleDoneTask(leaf.task, done),
                                    onEdit: (leaf) =>
                                        _editTaskEntity(leaf.task),
                                    onMove: (leaf) =>
                                        _moveTaskEntity(leaf.task),
                                    onDelete: (leaf) =>
                                        _confirmDeleteTask(leaf.task),
                                  )
                                : _TaskTree(
                                    nodes: _flatten(roots),
                                    activeTaskId: activeTaskId,
                                    activeStartedAt: activeTimerStartedAt,
                                    onAddSubtask: _startSubtask,
                                    onToggleTimer: _toggleTimer,
                                    onAddTime: _addTime,
                                    onToggleDone: _toggleDone,
                                    onDelete: _confirmDelete,
                                    onEdit: _editTask,
                                    onMove: _moveTask,
                                  ),
                          ),
                        ],
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
    required this.activeStartedAt,
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
  final DateTime? activeStartedAt;
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
      itemBuilder: (context, i) {
        final isActive = nodes[i].task.id == activeTaskId;
        return TaskNodeTile(
          node: nodes[i],
          isActive: isActive,
          activeStartedAt: isActive ? activeStartedAt : null,
          onAddSubtask: onAddSubtask,
          onToggleTimer: onToggleTimer,
          onAddTime: onAddTime,
          onToggleDone: onToggleDone,
          onDelete: onDelete,
          onEdit: onEdit,
          onMove: onMove,
        );
      },
    );
  }
}

class _PriorityList extends StatelessWidget {
  const _PriorityList({
    required this.leaves,
    required this.activeTaskId,
    required this.activeStartedAt,
    required this.onToggleTimer,
    required this.onAddTime,
    required this.onToggleDone,
    required this.onEdit,
    required this.onMove,
    required this.onDelete,
  });

  final List<PrioritizedLeaf> leaves;
  final String? activeTaskId;
  final DateTime? activeStartedAt;
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
          activeStartedAt: isActive ? activeStartedAt : null,
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
