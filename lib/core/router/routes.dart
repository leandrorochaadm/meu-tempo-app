/// Nomes de rota centralizados (proibido path literal espalhado).
class Routes {
  const Routes._();

  static const String login = '/login';
  static const String home = '/';
  static const String lists = '/lists';
  static const String agenda = '/agenda';
  static const String report = '/report';
  static const String migration = '/migration';
  static const String settings = '/settings';

  /// Edição de tarefa — recebe a `TaskEntity` alvo via `state.extra`.
  static const String editTask = '/task/edit';
}
