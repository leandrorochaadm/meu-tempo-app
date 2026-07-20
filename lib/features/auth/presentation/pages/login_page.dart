import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_primary_button.dart';
import '../bloc/auth_bloc.dart';

/// Tela de login — botão único "Entrar com Google".
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listenWhen: (_, curr) => curr is AuthError,
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            final loading = state is AuthLoading;
            return Padding(
              padding: EdgeInsets.all(context.space.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Meu Tempo', style: context.text.displayLarge),
                  SizedBox(height: context.space.sm),
                  Text(
                    'Seu Bullet Journal digital com cronômetro por tarefa.',
                    style: context.text.bodySmall,
                  ),
                  SizedBox(height: context.space.xxxl),
                  AppPrimaryButton(
                    label: 'Entrar com Google',
                    icon: Icons.login_rounded,
                    loading: loading,
                    onPressed: () => context
                        .read<AuthBloc>()
                        .add(const AuthGoogleSignInRequested()),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
