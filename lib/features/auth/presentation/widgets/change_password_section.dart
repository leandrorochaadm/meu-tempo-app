import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/autofill_form_reset.dart';
import '../account_field_error_label.dart';
import '../bloc/change_password_bloc.dart';
import 'change_password_form_widget.dart';

/// "Trocar senha" part of the Profile block in Settings.
class ChangePasswordSection extends StatelessWidget {
  const ChangePasswordSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChangePasswordBloc>(),
      child: const _ChangePasswordView(),
    );
  }
}

class _ChangePasswordView extends StatefulWidget {
  const _ChangePasswordView();

  @override
  State<_ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<_ChangePasswordView> {
  // Changing the key rebuilds the form, which clears the fields.
  int _formGeneration = 0;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChangePasswordBloc, ChangePasswordState>(
      listener: (context, state) {
        if (state is ChangePasswordFailed || state is ChangePasswordInvalid) {
          // Clicking the button left the dormant autofill form behind.
          resetAutofillForm();
        }
        if (state is ChangePasswordDone) {
          setState(() => _formGeneration++);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Senha trocada.')));
        }
      },
      child: BlocBuilder<ChangePasswordBloc, ChangePasswordState>(
        builder: (context, state) {
          final currentPasswordError = switch (state) {
            ChangePasswordFailed(
              :final message,
              field: ChangePasswordFieldEnum.currentPassword,
            ) =>
              message,
            _ => null,
          };
          final newPasswordError = switch (state) {
            ChangePasswordInvalid(:final errors) => errors.first.label,
            _ => null,
          };
          final generalError = switch (state) {
            ChangePasswordFailed(:final message, field: null) => message,
            _ => null,
          };
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChangePasswordFormWidget(
                key: ValueKey(_formGeneration),
                onSubmit: (current, next) =>
                    context.read<ChangePasswordBloc>().add(
                      ChangePasswordSubmitted(
                        currentPassword: current,
                        newPassword: next,
                      ),
                    ),
                loading: state is ChangePasswordInProgress,
                currentPasswordError: currentPasswordError,
                newPasswordError: newPasswordError,
              ),
              if (generalError != null) ...[
                SizedBox(height: context.space.sm),
                Text(
                  generalError,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.danger,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
