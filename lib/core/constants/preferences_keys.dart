/// Chaves das preferências de UI locais (device), guardadas via
/// `shared_preferences`. Nunca usar a string literal espalhada pelo código
/// (regra `enums.md`) — sempre referenciar por aqui.
class PreferencesKeys {
  const PreferencesKeys._();

  /// Lista selecionada como filtro da tela principal (`null`/ausente = todas).
  static const String taskListFilter = 'task_list_filter';
}
