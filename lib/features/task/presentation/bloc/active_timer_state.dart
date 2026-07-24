part of 'active_timer_bloc.dart';

sealed class ActiveTimerState extends Equatable {
  const ActiveTimerState();

  @override
  List<Object?> get props => const [];
}

/// Nenhum cronômetro rodando numa tarefa folha — a barra não aparece. Cobre
/// também o cronômetro num compromisso (a barra é só para tarefas) e o estado
/// deslogado.
class ActiveTimerHidden extends ActiveTimerState {
  const ActiveTimerHidden();
}

/// Cronômetro rodando numa folha — a barra "now playing" é exibida.
class ActiveTimerRunning extends ActiveTimerState {
  const ActiveTimerRunning({
    required this.title,
    required this.ancestryLabel,
    required this.startedAt,
    required this.editContext,
    required this.lists,
  });

  /// Nome da folha em contagem.
  final String title;

  /// Trilha "mãe › avó" (vazia se a folha for raiz).
  final String ancestryLabel;

  /// Início da sessão atual — base do contador ao vivo hh:mm:ss.
  final DateTime startedAt;

  /// Contexto pronto para abrir a edição (candidatos a mãe + breadcrumb).
  final TaskEditContext editContext;

  /// Listas do usuário — necessárias para montar os argumentos da edição.
  final List<TaskListEntity> lists;

  String get taskId => editContext.task.id;

  @override
  List<Object?> get props => [title, ancestryLabel, startedAt, editContext, lists];
}

/// Efeito colateral transitório: uma ação (parar/concluir/editar) falhou. Serve
/// só para o `BlocListener` exibir um aviso — o `BlocBuilder` o ignora (via
/// `buildWhen`), então a barra permanece renderizando o estado anterior.
class ActiveTimerActionFailed extends ActiveTimerState {
  const ActiveTimerActionFailed(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
