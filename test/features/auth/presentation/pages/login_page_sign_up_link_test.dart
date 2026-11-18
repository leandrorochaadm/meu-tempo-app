import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_tempo/core/router/routes.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_tempo/features/auth/presentation/pages/login_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  // REQ-001: the login screen footer offers "Criar conta" and opens the sign-up screen
  testWidgets(
    'should show Não tem conta? and open sign-up when tapping Criar conta',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final authBloc = _MockAuthBloc();
      when(() => authBloc.state).thenReturn(const AuthUnauthenticated());
      final router = GoRouter(
        initialLocation: Routes.login,
        routes: [
          GoRoute(
            path: Routes.login,
            builder: (_, _) => BlocProvider<AuthBloc>.value(
              value: authBloc,
              child: const LoginPage(),
            ),
          ),
          GoRoute(
            path: Routes.signUp,
            builder: (_, _) => const Text('sign-up'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      );
      await tester.pumpAndSettle();

      expect(find.text('Não tem conta?'), findsOneWidget);
      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();

      expect(find.text('sign-up'), findsOneWidget);
    },
  );
}
