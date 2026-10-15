import '../../features/task/domain/entities/timer_target_type_enum.dart';

/// Nomes de rota centralizados (proibido path literal espalhado).
class Routes {
  const Routes._();

  static const String login = '/login';
  static const String home = '/';
  static const String lists = '/lists';

  /// Tarefas recorrentes (modelos de tarefa) — CRUD e "Adicionar hoje" (H15).
  static const String recurringTasks = '/recurring-tasks';
  static const String agenda = '/agenda';
  static const String report = '/report';

  /// Detalhe do relatório de uma lista. Recebe `list`, `period` e `offset` como
  /// query params (sobrevive a refresh no navegador); `listName` vem por `extra`.
  static const String reportDetail = '/report/detail';
  static const String settings = '/settings';

  /// Edição de tarefa — recebe `EditTaskArgs` via `state.extra`.
  static const String editTask = '/task/edit';

  /// Registros de tempo de uma folha (CRUD) — recebe a `TaskEntity` folha via
  /// `state.extra`.
  static const String timeEntry = '/task/time-entries';

  /// Opens the timer target — tap on the lock screen and deep link. Takes `type`
  /// (`TimerTargetTypeEnum.apiValue`) and `id` as query params (survives a
  /// browser refresh). Task → edit; appointment → agenda. Build the address
  /// with [timerTargetLocation].
  static const String timerTarget = '/timer-target';

  /// Full address of [timerTarget] for the target [type]/[id].
  static String timerTargetLocation(TimerTargetTypeEnum type, String id) => Uri(
    path: timerTarget,
    queryParameters: {
      TimerTargetQueryParams.type: type.apiValue,
      TimerTargetQueryParams.id: id,
    },
  ).toString();
}

/// Query param names of [Routes.timerTarget].
class TimerTargetQueryParams {
  const TimerTargetQueryParams._();

  static const String type = 'type';
  static const String id = 'id';
}
