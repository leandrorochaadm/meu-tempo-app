part of 'task_list_bloc.dart';

sealed class TaskListState extends Equatable {
  const TaskListState();

  @override
  List<Object?> get props => const [];
}

class TaskListLoading extends TaskListState {
  const TaskListLoading();
}

class TaskListLoaded extends TaskListState {
  const TaskListLoaded(
    this.roots, {
    this.prioritized = const [],
    this.activeTaskId,
    this.activeTimerStartedAt,
    this.lists = const [],
    this.selectedListId,
    this.hideDone = true,
    this.quickAddTarget,
    this.offeredParent,
    this.creationListId,
  });

  /// Árvore de tarefas (raízes = mães), com agregação pronta nos [TaskNode].
  final List<TaskNode> roots;

  /// Folhas não concluídas ordenadas por prioridade (lista plana).
  final List<PrioritizedLeaf> prioritized;

  /// Id da folha com cronômetro rodando (`null` = nenhum).
  final String? activeTaskId;

  /// Início da sessão do cronômetro ativo (`null` = nenhum) — base do contador
  /// ao vivo hh:mm:ss no selo da tarefa em execução.
  final DateTime? activeTimerStartedAt;

  /// Listas do usuário (para escolher onde criar a tarefa e filtrar).
  final List<TaskListEntity> lists;

  /// Lista escolhida como filtro da tela (`null` = "Todas as listas").
  final String? selectedListId;

  /// Se as tarefas concluídas estão ocultas (padrão `true`). Reflete o chip.
  final bool hideDone;

  /// Alvo ativo da barra de criação (`null` = criar tarefa mãe).
  final QuickAddTargetEntity? quickAddTarget;

  /// Última criada, oferecida como mãe do próximo lançamento (`null` = sem
  /// oferta, inclusive quando a última é neta e não aceita filha).
  final QuickAddTargetEntity? offeredParent;

  /// Lista onde a próxima tarefa raiz nasce — já resolvida no domínio.
  final String? creationListId;

  @override
  List<Object?> get props => [
    roots,
    prioritized,
    activeTaskId,
    activeTimerStartedAt,
    lists,
    selectedListId,
    hideDone,
    quickAddTarget,
    offeredParent,
    creationListId,
  ];
}

class TaskListEmpty extends TaskListState {
  const TaskListEmpty();
}

class TaskListError extends TaskListState {
  const TaskListError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
