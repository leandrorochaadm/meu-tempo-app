import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_primary_button.dart';
import '../account_field_error_label.dart';
import '../bloc/change_password_form_bloc.dart';
import 'password_checklist_widget.dart';

/// "Trocar senha" section, ready to be placed in the profile screen.
class ChangePasswordFormWidget extends StatelessWidget {
  const ChangePasswordFormWidget({super.key, required this.onSubmit});

  final void Function(String currentPassword, String newPassword) onSubmit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChangePasswordFormBloc>(),
      child: _ChangePasswordFormView(onSubmit: onSubmit),
    );
  }
}

class _ChangePasswordFormView extends StatefulWidget {
  const _ChangePasswordFormView({required this.onSubmit});

  final void Function(String currentPassword, String newPassword) onSubmit;

  @override
  State<_ChangePasswordFormView> createState() =>
      _ChangePasswordFormViewState();
}

class _ChangePasswordFormViewState extends State<_ChangePasswordFormView> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    super.dispose();
  }

  void _changed() {
    context.read<ChangePasswordFormBloc>().add(
      ChangePasswordFormChanged(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      ),
    );
  }

  Widget _eye(bool obscure, VoidCallback onPressed) => IconButton(
    tooltip: obscure ? 'Mostrar senha' : 'Esconder senha',
    icon: Icon(
      obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
    ),
    onPressed: onPressed,
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChangePasswordFormBloc, ChangePasswordFormState>(
      builder: (context, state) {
        switch (state) {
          case ChangePasswordFormEditing(:final form):
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Trocar senha', style: context.text.titleMedium),
                SizedBox(height: context.space.md),
                TextField(
                  controller: _currentController,
                  onChanged: (_) => _changed(),
                  style: context.text.bodyMedium,
                  obscureText: _obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Senha atual',
                    suffixIcon: _eye(
                      _obscureCurrent,
                      () => setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.password],
                ),
                SizedBox(height: context.space.lg),
                TextField(
                  controller: _newController,
                  onChanged: (_) => _changed(),
                  style: context.text.bodyMedium,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Senha nova',
                    errorText: form.newPasswordWarning?.label,
                    suffixIcon: _eye(
                      _obscureNew,
                      () => setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                ),
                SizedBox(height: context.space.sm),
                PasswordChecklistWidget(metRules: form.metPasswordRules),
                SizedBox(height: context.space.lg),
                AppPrimaryButton(
                  label: 'Trocar senha',
                  onPressed: form.canSubmit
                      ? () => widget.onSubmit(
                          _currentController.text,
                          _newController.text,
                        )
                      : null,
                ),
              ],
            );
        }
      },
    );
  }
}
