import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'page_reload.dart';

/// Tela de último recurso exibida via `ErrorWidget.builder` quando algo estoura
/// no `build` (em release o Flutter mostraria uma tela cinza). Fica no `core`
/// (não na `presentation`) e **não depende do tema** — usa `AppColors.dark`
/// direto, porque o próprio tema pode ser a origem da falha. Por isso as cores
/// aparecem aqui em vez de virem do `context` (exceção consciente à regra de
/// formatação, restrita a este fallback).
class AppErrorScreen extends StatelessWidget {
  const AppErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.dark;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: colors.bgBase,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: colors.danger, size: 48),
            const SizedBox(height: 20),
            Text(
              'Algo deu errado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Não foi possível carregar o app. Recarregue para tentar de novo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 15,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            _ReloadButton(colors: colors),
          ],
        ),
      ),
    );
  }
}

class _ReloadButton extends StatelessWidget {
  const _ReloadButton({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.primary,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: reloadPage,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          child: Text(
            'Recarregar',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
