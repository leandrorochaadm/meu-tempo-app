import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme_context_extensions.dart';

/// Envolve um item de tarefa com gestos rápidos (diretriz de fricção zero):
/// - arrastar → (startToEnd): concluir (só quando [onSwipeComplete] != null);
/// - arrastar ← (endToStart): editar;
/// - clique longo: excluir.
///
/// Usa `Dismissible` apenas pelo feedback de arrasto (fundo colorido + ícone) —
/// `confirmDismiss` sempre retorna `false`, então o item volta ao lugar e a lista
/// se atualiza pelo stream do Bloc (concluir/editar não removem o card à mão).
class SwipeActionTile extends StatelessWidget {
  const SwipeActionTile({
    super.key,
    required this.itemKey,
    required this.onSwipeEdit,
    required this.onLongPressDelete,
    this.onSwipeComplete,
    required this.child,
  });

  /// Chave estável do item (ex.: `ValueKey(task.id)`), exigida pelo Dismissible.
  final Key itemKey;
  final VoidCallback onSwipeEdit;
  final VoidCallback onLongPressDelete;

  /// Concluir. `null` desabilita o swipe para a direita (mãe/avó não concluem).
  final VoidCallback? onSwipeComplete;
  final Widget child;

  /// Fração da largura que o arrasto precisa cruzar para disparar a ação.
  /// Padrão do Dismissible é 0.4; reduzido para gesto mais leve no celular.
  static const double _dismissThreshold = 0.25;

  @override
  Widget build(BuildContext context) {
    final canComplete = onSwipeComplete != null;

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPressDelete();
      },
      child: Dismissible(
        key: itemKey,
        direction: canComplete
            ? DismissDirection.horizontal
            : DismissDirection.endToStart,
        dismissThresholds: const {
          DismissDirection.startToEnd: _dismissThreshold,
          DismissDirection.endToStart: _dismissThreshold,
        },
        // Nunca descarta de fato: dispara a ação e volta ao lugar.
        confirmDismiss: (direction) async {
          HapticFeedback.lightImpact();
          if (direction == DismissDirection.startToEnd) {
            onSwipeComplete?.call();
          } else {
            onSwipeEdit();
          }
          return false;
        },
        // O Dismissible exige `background != null` quando há `secondaryBackground`.
        // Com conclusão: background=concluir (→), secondaryBackground=editar (←).
        // Sem conclusão (mãe/avó): só editar (←) — vai no background, sem secundário.
        background: canComplete
            ? _ActionBackground(
                color: context.colors.success,
                icon: Icons.check_circle_rounded,
                alignment: Alignment.centerLeft,
              )
            : _ActionBackground(
                color: context.colors.primary,
                icon: Icons.edit_rounded,
                alignment: Alignment.centerRight,
              ),
        secondaryBackground: canComplete
            ? _ActionBackground(
                color: context.colors.primary,
                icon: Icons.edit_rounded,
                alignment: Alignment.centerRight,
              )
            : null,
        child: child,
      ),
    );
  }
}

/// Fundo colorido revelado durante o arrasto, com o ícone da ação alinhado ao
/// lado de onde o gesto começa.
class _ActionBackground extends StatelessWidget {
  const _ActionBackground({
    required this.color,
    required this.icon,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: EdgeInsets.symmetric(horizontal: context.space.lg),
      decoration: BoxDecoration(
        color: color,
        borderRadius: context.radius.lgRadius,
      ),
      child: Icon(icon, color: context.colors.onPrimary),
    );
  }
}
