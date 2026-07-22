import 'package:flutter/material.dart';

import '../constants/app_defaults.dart';

/// Snackbar de ação desfazível (concluir/excluir) — centraliza o padrão de undo
/// exigido pelas ações destrutivas (H13, ver `layout.md`).
///
/// Garante `persist: false`: a partir do Flutter 3.41 o `persist` do [SnackBar]
/// assume `true` quando há `action`, o que **ignora** o `duration` e deixa o
/// snackbar fixo na tela. Forçamos `false` para ele sumir sozinho na duração
/// padrão ([AppDefaults.undoSnackbarDuration]).
abstract final class AppUndoSnackBar {
  /// Substitui o snackbar atual por um de undo com [message] e um botão que
  /// dispara [onUndo].
  static void show(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    String actionLabel = 'Desfazer',
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          persist: false,
          duration: AppDefaults.undoSnackbarDuration,
          content: Text(message),
          action: SnackBarAction(label: actionLabel, onPressed: onUndo),
        ),
      );
  }
}
