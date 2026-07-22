/// Defaults de negócio nomeados (proibido número/string mágico no meio do código).
class AppDefaults {
  const AppDefaults._();

  /// Nome da lista fixa padrão (destino da criação rápida).
  static const String inboxListName = 'Entrada';

  /// Tempo estimado padrão da criação rápida (minutos).
  static const int defaultEstimatedMinutes = 30;

  /// Tempo que o snackbar de "Desfazer" (concluir/excluir) fica visível.
  static const Duration undoSnackbarDuration = Duration(seconds: 10);
}
