import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/core/ui/app_primary_button.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_tempo/features/auth/presentation/pages/login_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  late _MockAuthBloc bloc;

  setUpAll(() => registerFallbackValue(const AuthSignOutRequested()));

  setUp(() {
    bloc = _MockAuthBloc();
    when(() => bloc.state).thenReturn(const AuthUnauthenticated());
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: BlocProvider<AuthBloc>.value(
          value: bloc,
          child: const LoginPage(),
        ),
      ),
    );
  }

  testWidgets('should show email and password fields, Entrar and help text', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Sem conta? Fale com quem cuida do app.'), findsOneWidget);
  });

  testWidgets(
    'should add AuthEmailSignInRequested with typed values when tapping Entrar',
    (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(TextField).first, ' a@b.com ');
      await tester.enterText(find.byType(TextField).last, ' pw ');
      await tester.tap(find.text('Entrar'));
      await tester.pump();
      verify(
        () => bloc.add(
          const AuthEmailSignInRequested(email: ' a@b.com ', password: ' pw '),
        ),
      ).called(1);
    },
  );

  testWidgets('should toggle password visibility', (tester) async {
    await pump(tester);
    bool obscured() =>
        tester.widget<TextField>(find.byType(TextField).last).obscureText;
    expect(obscured(), isTrue);
    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pump();
    expect(obscured(), isFalse);
    expect(find.byTooltip('Esconder senha'), findsOneWidget);
  });

  testWidgets('should not add event when tapping Entrar while loading', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(const AuthLoading());
    await pump(tester);
    await tester.tap(find.byType(AppPrimaryButton), warnIfMissed: false);
    await tester.pump();
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('should show snackbar with message on AuthError', (tester) async {
    whenListen(
      bloc,
      Stream<AuthState>.fromIterable([
        const AuthError('E-mail ou senha incorretos.'),
      ]),
      initialState: const AuthUnauthenticated(),
    );
    await pump(tester);
    await tester.enterText(find.byType(TextField).first, 'a@b.com');
    await tester.pump();
    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
    expect(find.text('a@b.com'), findsOneWidget);
  });
}
