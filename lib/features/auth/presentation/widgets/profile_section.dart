import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_primary_button.dart';
import '../account_field_error_label.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/update_display_name_bloc.dart';

/// "Perfil" section of Settings: edit the display name.
class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<UpdateDisplayNameBloc>(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  late final TextEditingController _controller;

  static String? _nameOf(AuthState state) =>
      state is AuthAuthenticated ? state.user.displayName : null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _nameOf(context.read<AuthBloc>().state) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              _nameOf(previous) != _nameOf(current),
          listener: (context, state) => _controller.text = _nameOf(state) ?? '',
        ),
        BlocListener<UpdateDisplayNameBloc, UpdateDisplayNameState>(
          listener: (context, state) {
            if (state is UpdateDisplayNameSaved) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Nome salvo.')));
            }
          },
        ),
      ],
      child: BlocBuilder<UpdateDisplayNameBloc, UpdateDisplayNameState>(
        builder: (context, state) {
          final errorText = switch (state) {
            UpdateDisplayNameInvalid(:final errors) => errors.first.label,
            UpdateDisplayNameFailed(:final message) => message,
            _ => null,
          };
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Perfil', style: context.text.titleMedium),
              SizedBox(height: context.space.md),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  hintText: 'Informe seu nome',
                  errorText: errorText,
                ),
              ),
              SizedBox(height: context.space.md),
              AppPrimaryButton(
                label: 'Salvar',
                icon: Icons.check_rounded,
                loading: state is UpdateDisplayNameInProgress,
                onPressed: () => context.read<UpdateDisplayNameBloc>().add(
                  UpdateDisplayNameSubmitted(_controller.text),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
