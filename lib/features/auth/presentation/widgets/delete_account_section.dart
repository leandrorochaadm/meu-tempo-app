import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_primary_button.dart';
import '../bloc/delete_account_bloc.dart';

/// "Conta" section of Settings: delete-account button with confirmation.
class DeleteAccountSection extends StatelessWidget {
  const DeleteAccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DeleteAccountBloc>(),
      child: const _DeleteAccountView(),
    );
  }
}

class _DeleteAccountView extends StatelessWidget {
  const _DeleteAccountView();

  Future<void> _confirm(BuildContext context) async {
    final bloc = context.read<DeleteAccountBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: const Text(
          'Isso apaga sua conta e todas as suas listas, tarefas, compromissos '
          'e tempos. Não tem volta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) bloc.add(const DeleteAccountRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeleteAccountBloc, DeleteAccountState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Conta', style: context.text.titleMedium),
            SizedBox(height: context.space.md),
            AppPrimaryButton(
              label: 'Excluir conta',
              icon: Icons.delete_forever_rounded,
              destructive: true,
              loading: state is DeleteAccountInProgress,
              onPressed: () => _confirm(context),
            ),
            if (state case DeleteAccountFailed(:final message)) ...[
              SizedBox(height: context.space.sm),
              Text(
                message,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.danger,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
