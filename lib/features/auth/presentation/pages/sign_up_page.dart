import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_links.dart';
import '../../../../core/error/account_field_error_enum.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_primary_button.dart';
import '../../../../core/ui/autofill_form_reset.dart';
import '../../domain/entities/sign_up_form_entity.dart';
import '../account_field_error_label.dart';
import '../bloc/sign_up_bloc.dart';
import '../widgets/password_checklist_widget.dart';

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
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  SignUpFormEntity? _form;

  @override
  void initState() {
    super.initState();
    final state = context.read<SignUpBloc>().state;
    _form = state is SignUpEditing ? state.form : null;
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) {
        context.read<SignUpBloc>().add(const SignUpDisplayNameLeft());
      }
    });
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) {
        context.read<SignUpBloc>().add(const SignUpEmailLeft());
      }
    });
  }

  void _formChanged() {
    if (context.read<SignUpBloc>().state is SignUpInProgress) return;
    context.read<SignUpBloc>().add(
      SignUpFormChanged(
        displayName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
  }

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
    _nameFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: BlocConsumer<SignUpBloc, SignUpState>(
          listenWhen: (_, curr) =>
              curr is SignUpFailed || curr is SignUpEditing,
          listener: (context, state) {
            if (state is SignUpEditing) {
              _form = state.form;
            }
            if (state is SignUpFailed) {
              // Unfocusing on submit left the dormant autofill form behind.
              resetAutofillForm();
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            final loading = state is SignUpInProgress;
            final form = state is SignUpEditing ? state.form : _form;
            final nameError =
                state is SignUpFieldsInvalid &&
                    state.errors.contains(
                      AccountFieldErrorEnum.displayNameLength,
                    )
                ? AccountFieldErrorEnum.displayNameLength.label
                : form?.displayNameWarning?.label;
            final emailError = switch (state) {
              SignUpEmailInUse(:final message) => message,
              SignUpFieldsInvalid(:final errors)
                  when errors.contains(AccountFieldErrorEnum.invalidEmail) =>
                AccountFieldErrorEnum.invalidEmail.label,
              _ => form?.emailWarning?.label,
            };
            final passwordError =
                state is SignUpFieldsInvalid &&
                    state.errors.contains(AccountFieldErrorEnum.passwordTooLong)
                ? AccountFieldErrorEnum.passwordTooLong.label
                : form?.passwordWarning?.label;
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
                            focusNode: _nameFocus,
                            onChanged: (_) => _formChanged(),
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
                            focusNode: _emailFocus,
                            onChanged: (_) => _formChanged(),
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
                            onChanged: (_) => _formChanged(),
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
                                onPressed: () {
                                  resetAutofillForm();
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                              ),
                            ),
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            onSubmitted: (_) {
                              if (!loading && (form?.canSubmit ?? true)) {
                                _submit();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    if (form != null) ...[
                      SizedBox(height: context.space.sm),
                      PasswordChecklistWidget(metRules: form.metPasswordRules),
                    ],
                    CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      value: _acceptedPrivacyPolicy,
                      onChanged: (value) {
                        setState(() => _acceptedPrivacyPolicy = value ?? false);
                        context.read<SignUpBloc>().add(
                          SignUpPrivacyPolicyChanged(value ?? false),
                        );
                        _formChanged();
                      },
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Li e aceito a', style: context.text.bodyMedium),
                          SizedBox(height: context.space.xxl),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
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
                      onPressed: (form?.canSubmit ?? true) ? _submit : null,
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
