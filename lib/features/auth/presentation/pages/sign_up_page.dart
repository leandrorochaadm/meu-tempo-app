import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_links.dart';
import '../../../../core/error/account_field_error_enum.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_primary_button.dart';
import '../account_field_error_label.dart';
import '../bloc/sign_up_bloc.dart';

/// "Criar conta" screen — name, email and password.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptedPrivacyPolicy = false;

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<SignUpBloc>().add(
      SignUpSubmitted(
        displayName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: BlocConsumer<SignUpBloc, SignUpState>(
          listenWhen: (_, curr) => curr is SignUpFailed,
          listener: (context, state) {
            if (state is SignUpFailed) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            final loading = state is SignUpInProgress;
            final nameError =
                state is SignUpFieldsInvalid &&
                    state.errors.contains(
                      AccountFieldErrorEnum.displayNameLength,
                    )
                ? AccountFieldErrorEnum.displayNameLength.label
                : null;
            final emailError =
                state is SignUpFieldsInvalid &&
                    state.errors.contains(AccountFieldErrorEnum.invalidEmail)
                ? AccountFieldErrorEnum.invalidEmail.label
                : null;
            final passwordError =
                state is SignUpFieldsInvalid &&
                    state.errors.contains(AccountFieldErrorEnum.passwordTooLong)
                ? AccountFieldErrorEnum.passwordTooLong.label
                : null;
            final policyError =
                state is SignUpFieldsInvalid &&
                    state.errors.contains(
                      AccountFieldErrorEnum.privacyPolicyNotAccepted,
                    )
                ? AccountFieldErrorEnum.privacyPolicyNotAccepted.label
                : null;
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(context.space.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutofillGroup(
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            style: context.text.bodyMedium,
                            decoration: InputDecoration(
                              labelText: 'Nome',
                              errorText: nameError,
                            ),
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                          ),
                          SizedBox(height: context.space.lg),
                          TextField(
                            controller: _emailController,
                            style: context.text.bodyMedium,
                            decoration: InputDecoration(
                              labelText: 'E-mail',
                              errorText: emailError,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            autocorrect: false,
                            enableSuggestions: false,
                          ),
                          SizedBox(height: context.space.lg),
                          TextField(
                            controller: _passwordController,
                            style: context.text.bodyMedium,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              errorText: passwordError,
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Mostrar senha'
                                    : 'Esconder senha',
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            onSubmitted: (_) {
                              if (!loading) _submit();
                            },
                          ),
                        ],
                      ),
                    ),
                    CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      value: _acceptedPrivacyPolicy,
                      onChanged: (value) {
                        setState(() => _acceptedPrivacyPolicy = value ?? false);
                        context.read<SignUpBloc>().add(
                          SignUpPrivacyPolicyChanged(value ?? false),
                        );
                      },
                      title: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Li e aceito a ',
                            style: context.text.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () => launchUrl(
                              Uri.parse(AppLinks.privacyPolicy),
                              mode: LaunchMode.externalApplication,
                            ),
                            child: const Text('política de privacidade'),
                          ),
                        ],
                      ),
                    ),
                    if (policyError != null)
                      Text(
                        policyError,
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.danger,
                        ),
                      ),
                    SizedBox(height: context.space.xxl),
                    AppPrimaryButton(
                      label: 'Criar conta',
                      icon: Icons.person_add_rounded,
                      loading: loading,
                      onPressed: _submit,
                    ),
                    SizedBox(height: context.space.lg),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('Já tem conta?', style: context.text.bodySmall),
                        TextButton(
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go(Routes.login),
                          child: const Text('Entrar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
