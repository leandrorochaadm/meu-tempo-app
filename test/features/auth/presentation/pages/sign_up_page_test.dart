import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_tempo/core/error/account_field_error_enum.dart';
import 'package:meu_tempo/core/router/routes.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/core/ui/app_primary_button.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/sign_up_bloc.dart';
import 'package:meu_tempo/features/auth/presentation/pages/sign_up_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockSignUpBloc extends MockBloc<SignUpEvent, SignUpState>
    implements SignUpBloc {}

void main() {
  late _MockSignUpBloc bloc;

  setUpAll(() {
    registerFallbackValue(
      const SignUpSubmitted(displayName: '', email: '', password: ''),
    );
  });

  setUp(() {
    bloc = _MockSignUpBloc();
    when(() => bloc.state).thenReturn(const SignUpIdle());
  });

  void useMobileViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pump(WidgetTester tester) async {
    useMobileViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: BlocProvider<SignUpBloc>.value(
          value: bloc,
          child: const SignUpPage(),
        ),
      ),
    );
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  // REQ-001: tapping "Criar conta" sends the typed name, email and password to the bloc
  testWidgets(
    'should add SignUpSubmitted with typed values when tapping Criar conta',
    (tester) async {
      await pump(tester);
      await tester.enterText(field('Nome'), 'Ana');
      await tester.enterText(field('E-mail'), 'ana@exemplo.com');
      await tester.enterText(field('Senha'), 'Abcd1234');
      await tester.tap(find.byType(AppPrimaryButton));
      await tester.pump();

      verify(
        () => bloc.add(
          const SignUpSubmitted(
            displayName: 'Ana',
            email: 'ana@exemplo.com',
            password: 'Abcd1234',
          ),
        ),
      ).called(1);
    },
  );

  // REQ-001: the sign-up screen shows its title, fields, button and the login link
  testWidgets(
    'should show name, email and password fields, Criar conta and Entrar link',
    (tester) async {
      await pump(tester);

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Criar conta'),
        ),
        findsOneWidget,
      );
      expect(field('Nome'), findsOneWidget);
      expect(field('E-mail'), findsOneWidget);
      expect(field('Senha'), findsOneWidget);
      expect(find.text('Criar conta'), findsNWidgets(2));
      expect(find.text('Já tem conta?'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
    },
  );

  // REQ-001: the eye icon shows and hides the password
  testWidgets('should toggle password visibility', (tester) async {
    await pump(tester);
    bool obscured() => tester.widget<TextField>(field('Senha')).obscureText;

    expect(obscured(), isTrue);
    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pump();
    expect(obscured(), isFalse);
    expect(find.byTooltip('Esconder senha'), findsOneWidget);

    await tester.tap(find.byTooltip('Esconder senha'));
    await tester.pump();
    expect(obscured(), isTrue);
    expect(find.byTooltip('Mostrar senha'), findsOneWidget);
  });

  // REQ-001: while sending, tapping "Criar conta" adds no event
  testWidgets(
    'should not add event when tapping Criar conta while in progress',
    (tester) async {
      when(() => bloc.state).thenReturn(const SignUpInProgress());
      await pump(tester);
      await tester.enterText(field('Nome'), 'Ana');
      await tester.tap(find.byType(AppPrimaryButton), warnIfMissed: false);
      await tester.pump();

      verifyNever(() => bloc.add(any()));
    },
  );

  // REQ-001: no internet shows the message in a snackbar
  testWidgets('should show snackbar with message on SignUpFailed', (
    tester,
  ) async {
    whenListen(
      bloc,
      Stream<SignUpState>.fromIterable([
        const SignUpFailed('Sem internet. Tente de novo.'),
      ]),
      initialState: const SignUpIdle(),
    );
    await pump(tester);
    await tester.pump();
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Sem internet. Tente de novo.'), findsOneWidget);
  });

  // REQ-001: "Já tem conta? Entrar" goes back to the login screen
  testWidgets('should go back to login when tapping Entrar', (tester) async {
    useMobileViewport(tester);
    final router = GoRouter(
      initialLocation: Routes.login,
      routes: [
        GoRoute(path: Routes.login, builder: (_, _) => const Text('login')),
        GoRoute(
          path: Routes.signUp,
          builder: (_, _) => BlocProvider<SignUpBloc>.value(
            value: bloc,
            child: const SignUpPage(),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    );
    unawaited(router.push(Routes.signUp));
    await tester.pumpAndSettle();
    expect(find.byType(SignUpPage), findsOneWidget);

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
    expect(find.byType(SignUpPage), findsNothing);
  });

  // REQ-002: state SignUpFieldsInvalid([displayNameLength]): 1 warning below Nome, 0 snackbars
  testWidgets('should show name length warning below Nome', (tester) async {
    when(() => bloc.state).thenReturn(
      SignUpFieldsInvalid([AccountFieldErrorEnum.displayNameLength]),
    );
    await pump(tester);

    expect(find.text('Use de 2 a 50 caracteres.'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  // REQ-002: state SignUpIdle: no name warning
  testWidgets('should not show name warning when idle', (tester) async {
    await pump(tester);

    expect(find.text('Use de 2 a 50 caracteres.'), findsNothing);
  });
}
