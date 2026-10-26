import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_primary_button.dart';
import '../bloc/auth_bloc.dart';

/// Tela de login — e-mail, senha e botão "Entrar".
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      AuthEmailSignInRequested(
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
            return Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(context.space.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Meu Tempo', style: context.text.displayLarge),
                      SizedBox(height: context.space.sm),
                      Text(
                        'Seu Bullet Journal digital com cronômetro por tarefa.',
                        style: context.text.bodySmall,
                      ),
                      SizedBox(height: context.space.xxxl),
                      AutofillGroup(
                        child: Column(
                          children: [
                            TextField(
                              controller: _emailController,
                              style: context.text.bodyMedium,
                              decoration: const InputDecoration(
                                labelText: 'E-mail',
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
                              autofillHints: const [AutofillHints.password],
                              onSubmitted: (_) {
                                if (!loading) _submit();
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: context.space.xxl),
                      AppPrimaryButton(
                        label: 'Entrar',
                        icon: Icons.login_rounded,
                        loading: loading,
                        onPressed: _submit,
                      ),
                      SizedBox(height: context.space.lg),
                      Text(
                        'Sem conta? Fale com quem cuida do app.',
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
