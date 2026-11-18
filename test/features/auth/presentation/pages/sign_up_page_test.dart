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

  // REQ-005: state SignUpEmailInUse: warning once below E-mail, no SnackBar
  testWidgets('should show email in use warning below E-mail', (tester) async {
    when(() => bloc.state).thenReturn(
      const SignUpEmailInUse('Este e-mail já tem conta. Entre com ele.'),
    );
    await pump(tester);

    expect(
      find.text('Este e-mail já tem conta. Entre com ele.'),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
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

  // REQ-010: state SignUpFieldsInvalid([invalidEmail]): "Confira o e-mail." once below E-mail, no name warning
  testWidgets('should show email warning below E-mail', (tester) async {
    when(
      () => bloc.state,
    ).thenReturn(SignUpFieldsInvalid([AccountFieldErrorEnum.invalidEmail]));
    await pump(tester);

    expect(find.text('Confira o e-mail.'), findsOneWidget);
    expect(find.text('Use de 2 a 50 caracteres.'), findsNothing);
  });

  // REQ-010, REQ-011: state SignUpFieldsInvalid([displayNameLength, invalidEmail]): both warnings at the same time
  testWidgets('should show name and email warnings together', (tester) async {
    when(() => bloc.state).thenReturn(
      SignUpFieldsInvalid([
        AccountFieldErrorEnum.displayNameLength,
        AccountFieldErrorEnum.invalidEmail,
      ]),
    );
    await pump(tester);

    expect(find.text('Use de 2 a 50 caracteres.'), findsOneWidget);
    expect(find.text('Confira o e-mail.'), findsOneWidget);
  });

  // REQ-010: state SignUpIdle: no e-mail warning
  testWidgets('should not show email warning when idle', (tester) async {
    await pump(tester);

    expect(find.text('Confira o e-mail.'), findsNothing);
  });

  // REQ-003: state SignUpFieldsInvalid([passwordTooLong]): "Use no máximo 71 caracteres." once below Senha
  testWidgets('should show long password warning under Senha', (tester) async {
    when(
      () => bloc.state,
    ).thenReturn(SignUpFieldsInvalid([AccountFieldErrorEnum.passwordTooLong]));
    await pump(tester);

    expect(find.text('Use no máximo 71 caracteres.'), findsOneWidget);
  });

  // REQ-003: state SignUpFieldsInvalid([passwordMissingDigit]): no text below Senha
  testWidgets('should not show criterion errors under Senha', (tester) async {
    when(() => bloc.state).thenReturn(
      SignUpFieldsInvalid([
        AccountFieldErrorEnum.passwordTooShort,
        AccountFieldErrorEnum.passwordMissingDigit,
        AccountFieldErrorEnum.passwordMissingUppercase,
        AccountFieldErrorEnum.passwordMissingLowercase,
      ]),
    );
    await pump(tester);

    expect(find.text('Pelo menos 1 número'), findsNothing);
    expect(find.text('Use no máximo 71 caracteres.'), findsNothing);
  });

  // REQ-004: sign-up screen open: 1 unchecked box and 1 link "política de privacidade"
  testWidgets('should show one unchecked box and one privacy policy link', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byType(Checkbox), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(
      find.widgetWithText(TextButton, 'política de privacidade'),
      findsOneWidget,
    );
  });

  // REQ-004: tapping the box adds SignUpPrivacyPolicyChanged(true) once and the box becomes checked
  testWidgets('should add SignUpPrivacyPolicyChanged when tapping the box', (
    tester,
  ) async {
    await pump(tester);
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    verify(() => bloc.add(const SignUpPrivacyPolicyChanged(true))).called(1);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });

  // REQ-004: state SignUpFieldsInvalid([privacyPolicyNotAccepted]): "Marque para continuar." once, no SnackBar
  testWidgets('should show Marque para continuar when policy is not accepted', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(
      SignUpFieldsInvalid([AccountFieldErrorEnum.privacyPolicyNotAccepted]),
    );
    await pump(tester);

    expect(find.text('Marque para continuar.'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  // REQ-004: state SignUpIdle: no policy warning
  testWidgets('should not show policy warning when idle', (tester) async {
    await pump(tester);

    expect(find.text('Marque para continuar.'), findsNothing);
  });

  // REQ-011: state with 6 field errors: name, email and policy warnings together, no password text, no SnackBar
  testWidgets(
    'should show name, email and policy warnings together for 6 errors',
    (tester) async {
      when(() => bloc.state).thenReturn(
        SignUpFieldsInvalid([
          AccountFieldErrorEnum.displayNameLength,
          AccountFieldErrorEnum.invalidEmail,
          AccountFieldErrorEnum.passwordTooShort,
          AccountFieldErrorEnum.passwordMissingDigit,
          AccountFieldErrorEnum.passwordMissingUppercase,
          AccountFieldErrorEnum.privacyPolicyNotAccepted,
        ]),
      );
      await pump(tester);

      expect(find.text('Use de 2 a 50 caracteres.'), findsOneWidget);
      expect(find.text('Confira o e-mail.'), findsOneWidget);
      expect(find.text('Marque para continuar.'), findsOneWidget);
      expect(find.text('Pelo menos 8 caracteres'), findsNothing);
      expect(find.text('Pelo menos 1 número'), findsNothing);
      expect(find.text('Pelo menos 1 letra maiúscula'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    },
  );

  // REQ-011: state with only invalidEmail: only the email warning
  testWidgets('should show only the email warning when only invalidEmail', (
    tester,
  ) async {
    when(
      () => bloc.state,
    ).thenReturn(SignUpFieldsInvalid([AccountFieldErrorEnum.invalidEmail]));
    await pump(tester);

    expect(find.text('Confira o e-mail.'), findsOneWidget);
    expect(find.text('Use de 2 a 50 caracteres.'), findsNothing);
    expect(find.text('Marque para continuar.'), findsNothing);
  });

  // REQ-011: valid data and no internet: SignUpFailed with the network message shows the snackbar
  testWidgets(
    'should show Sem internet snackbar when SignUpFailed has the network message',
    (tester) async {
      whenListen(
        bloc,
        Stream.fromIterable([
          const SignUpFailed('Sem internet. Tente de novo.'),
        ]),
        initialState: const SignUpIdle(),
      );
      await pump(tester);
      await tester.pump();

      expect(find.text('Sem internet. Tente de novo.'), findsOneWidget);
    },
  );

  // REQ-011: valid data and the server fails: SignUpFailed with the generic message shows the snackbar
  testWidgets(
    'should show generic snackbar when SignUpFailed has the server message',
    (tester) async {
      whenListen(
        bloc,
        Stream.fromIterable([
          const SignUpFailed('Não foi possível criar a conta. Tente de novo.'),
        ]),
        initialState: const SignUpIdle(),
      );
      await pump(tester);
      await tester.pump();

      expect(
        find.text('Não foi possível criar a conta. Tente de novo.'),
        findsOneWidget,
      );
    },
  );
}
