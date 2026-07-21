/// Nomes de rota centralizados (proibido path literal espalhado).
class Routes {
  const Routes._();

  static const String login = '/login';
  static const String home = '/';
  static const String lists = '/lists';
  static const String agenda = '/agenda';
  static const String report = '/report';

  /// Detalhe do relatório de uma lista. Recebe `list`, `period` e `offset` como
  /// query params (sobrevive a refresh no navegador); `listName` vem por `extra`.
  static const String reportDetail = '/report/detail';
  static const String migration = '/migration';
  static const String settings = '/settings';

  /// Edição de tarefa — recebe `EditTaskArgs` via `state.extra`.
  static const String editTask = '/task/edit';

  /// Registros de tempo de uma folha (CRUD) — recebe a `TaskEntity` folha via
  /// `state.extra`.
  static const String timeEntry = '/task/time-entries';
}
