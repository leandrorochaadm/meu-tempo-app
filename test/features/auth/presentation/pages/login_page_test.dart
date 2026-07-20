import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_tempo/features/auth/presentation/pages/login_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late _MockAuthBloc authBloc;

  setUp(() {
    authBloc = _MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthUnauthenticated());
  });

  Widget harness() => MaterialApp(
        theme: AppTheme.dark,
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const LoginPage(),
        ),
      );

  testWidgets('mostra o botão Entrar com Google', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(harness());

    expect(find.text('Entrar com Google'), findsOneWidget);
    expect(find.text('Meu Tempo'), findsOneWidget);
  });

  testWidgets('tap no botão dispara AuthGoogleSignInRequested', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(harness());
    await tester.tap(find.text('Entrar com Google'));
    await tester.pump();

    verify(() => authBloc.add(const AuthGoogleSignInRequested())).called(1);
  });
}
