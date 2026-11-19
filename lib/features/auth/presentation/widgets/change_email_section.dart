import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_primary_button.dart';
import '../../../../core/ui/autofill_form_reset.dart';
import '../account_field_error_label.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/change_email_bloc.dart';

/// "Trocar e-mail" part of the Profile block in Settings.
class ChangeEmailSection extends StatelessWidget {
  const ChangeEmailSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChangeEmailBloc>(),
      child: const _ChangeEmailView(),
    );
  }
}

class _ChangeEmailView extends StatefulWidget {
  const _ChangeEmailView();

  @override
  State<_ChangeEmailView> createState() => _ChangeEmailViewState();
}

class _ChangeEmailViewState extends State<_ChangeEmailView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _eye() => IconButton(
    tooltip: _obscurePassword ? 'Mostrar senha' : 'Esconder senha',
    icon: Icon(
      _obscurePassword
          ? Icons.visibility_rounded
          : Icons.visibility_off_rounded,
    ),
    onPressed: () {
      resetAutofillForm();
      setState(() => _obscurePassword = !_obscurePassword);
    },
  );

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChangeEmailBloc, ChangeEmailState>(
      listener: (context, state) {
        if (state is ChangeEmailFailed || state is ChangeEmailInvalid) {
          // Clicking the button left the dormant autofill form behind.
          resetAutofillForm();
        }
        if (state is ChangeEmailDone) {
          _emailController.clear();
          _passwordController.clear();
          setState(() => _obscurePassword = true);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('E-mail trocado.')));
        }
      },
      child: BlocBuilder<ChangeEmailBloc, ChangeEmailState>(
        builder: (context, state) {
          final emailError = switch (state) {
            ChangeEmailInvalid(:final errors) => errors.first.label,
            ChangeEmailFailed(
              :final message,
              field: ChangeEmailFieldEnum.newEmail,
            ) =>
              message,
            _ => null,
          };
          final passwordError = switch (state) {
            ChangeEmailFailed(
              :final message,
              field: ChangeEmailFieldEnum.currentPassword,
            ) =>
              message,
            _ => null,
          };
          final generalError = switch (state) {
            ChangeEmailFailed(:final message, field: null) => message,
            _ => null,
          };
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Trocar e-mail', style: context.text.titleMedium),
              SizedBox(height: context.space.md),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  if (authState is! AuthAuthenticated) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: EdgeInsets.only(bottom: context.space.md),
                    child: Text(
                      'E-mail atual: ${authState.user.email}',
                      style: context.text.bodyMedium?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  labelText: 'E-mail novo',
                  errorText: emailError,
                ),
              ),
              SizedBox(height: context.space.md),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Senha atual',
                  errorText: passwordError,
                  suffixIcon: _eye(),
                ),
              ),
              SizedBox(height: context.space.md),
              ListenableBuilder(
                listenable: Listenable.merge([
                  _emailController,
                  _passwordController,
                ]),
                builder: (context, _) {
                  final filled =
                      _emailController.text.isNotEmpty &&
                      _passwordController.text.isNotEmpty;
                  return AppPrimaryButton(
                    label: 'Trocar e-mail',
                    icon: Icons.alternate_email_rounded,
                    loading: state is ChangeEmailInProgress,
                    onPressed: filled
                        ? () => context.read<ChangeEmailBloc>().add(
                            ChangeEmailSubmitted(
                              newEmail: _emailController.text,
                              currentPassword: _passwordController.text,
                            ),
                          )
                        : null,
                  );
                },
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
