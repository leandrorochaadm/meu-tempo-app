import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/di/injection.dart';
import 'package:meu_tempo/core/error/account_field_error_enum.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/auth/domain/entities/user_entity.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/change_email_bloc.dart';
import 'package:meu_tempo/features/auth/presentation/widgets/change_email_section.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/autofill_test_support.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockChangeEmailBloc extends MockBloc<ChangeEmailEvent, ChangeEmailState>
    implements ChangeEmailBloc {}

void main() {
  late _MockAuthBloc authBloc;
  late _MockChangeEmailBloc bloc;

  setUpAll(
    () => registerFallbackValue(
      const ChangeEmailSubmitted(newEmail: 'x', currentPassword: 'x'),
    ),
  );

  setUp(() {
    authBloc = _MockAuthBloc();
    bloc = _MockChangeEmailBloc();
    when(() => bloc.state).thenReturn(const ChangeEmailIdle());
    when(() => authBloc.state).thenReturn(
      const AuthAuthenticated(
        UserEntity(uid: 'u1', email: 'ana@exemplo.com', displayName: 'Ana'),
      ),
    );
    getIt.registerFactory<ChangeEmailBloc>(() => bloc);
  });

  tearDown(() => getIt.unregister<ChangeEmailBloc>());

  Widget harness() => MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: SingleChildScrollView(
        child: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const ChangeEmailSection(),
        ),
      ),
    ),
  );

  final newEmailFinder = find.widgetWithText(TextField, 'E-mail novo');
  final passwordFinder = find.widgetWithText(TextField, 'Senha atual');
  final buttonFinder = find.widgetWithText(FilledButton, 'Trocar e-mail');

  Future<void> fillBoth(WidgetTester tester) async {
    await tester.enterText(newEmailFinder, 'ana.lima@exemplo.com');
    await tester.enterText(passwordFinder, 'abcd1234');
    await tester.pump();
  }

  // REQ-007: Ana types and taps "Trocar e-mail": ChangeEmailSubmitted with both texts
  testWidgets('should submit typed e-mail and password when button is tapped', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    await fillBoth(tester);
    await tester.tap(buttonFinder);
    await tester.pump();

    verify(
      () => bloc.add(
        const ChangeEmailSubmitted(
          newEmail: 'ana.lima@exemplo.com',
          currentPassword: 'abcd1234',
        ),
      ),
    ).called(1);
  });

  // REQ-007: success clears both fields and shows "E-mail trocado."
  testWidgets('should clear fields and show "E-mail trocado." when done', (
    tester,
  ) async {
    final states = StreamController<ChangeEmailState>();
    addTearDown(states.close);
    whenListen(bloc, states.stream, initialState: const ChangeEmailIdle());
    await tester.pumpWidget(harness());
    await fillBoth(tester);
    states.add(const ChangeEmailDone());
    await tester.pump();
    await tester.pump();

    expect(find.text('E-mail trocado.'), findsOneWidget);
    expect(tester.widget<TextField>(newEmailFinder).controller?.text, isEmpty);
    expect(tester.widget<TextField>(passwordFinder).controller?.text, isEmpty);
  });

  // REQ-007: the current e-mail comes from AuthBloc and follows its changes
  testWidgets('should show current e-mail from AuthBloc', (tester) async {
    whenListen(
      authBloc,
      Stream<AuthState>.fromIterable([
        const AuthAuthenticated(
          UserEntity(
            uid: 'u1',
            email: 'ana.lima@exemplo.com',
            displayName: 'Ana',
          ),
        ),
      ]),
      initialState: const AuthAuthenticated(
        UserEntity(uid: 'u1', email: 'ana@exemplo.com', displayName: 'Ana'),
      ),
    );
    await tester.pumpWidget(harness());
    expect(find.text('E-mail atual: ana@exemplo.com'), findsOneWidget);

    await tester.pump();
    expect(find.text('E-mail atual: ana.lima@exemplo.com'), findsOneWidget);
  });

  // REQ-007: same e-mail refused: "Esse já é o seu e-mail." under the new e-mail
  testWidgets('should show "Esse já é o seu e-mail." under new e-mail', (
    tester,
  ) async {
    when(
      () => bloc.state,
    ).thenReturn(ChangeEmailInvalid([AccountFieldErrorEnum.sameEmail]));
    await tester.pumpWidget(harness());

    expect(find.text('Esse já é o seu e-mail.'), findsOneWidget);
    expect(
      tester.widget<TextField>(newEmailFinder).decoration?.errorText,
      'Esse já é o seu e-mail.',
    );
  });

  // REQ-007: wrong current password: message under the current password, current e-mail kept
  testWidgets(
    'should show "Senha atual incorreta." under current password and keep current e-mail',
    (tester) async {
      when(() => bloc.state).thenReturn(
        const ChangeEmailFailed(
          'Senha atual incorreta.',
          field: ChangeEmailFieldEnum.currentPassword,
        ),
      );
      await tester.pumpWidget(harness());

      expect(
        tester.widget<TextField>(passwordFinder).decoration?.errorText,
        'Senha atual incorreta.',
      );
      expect(find.text('E-mail atual: ana@exemplo.com'), findsOneWidget);
    },
  );

  // REQ-007: e-mail already in use: message under the new e-mail
  testWidgets('should show "Este e-mail já tem conta." under new e-mail', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(
      const ChangeEmailFailed(
        'Este e-mail já tem conta.',
        field: ChangeEmailFieldEnum.newEmail,
      ),
    );
    await tester.pumpWidget(harness());

    expect(
      tester.widget<TextField>(newEmailFinder).decoration?.errorText,
      'Este e-mail já tem conta.',
    );
  });

  // Offline: general message below the button, on no field
  testWidgets('should show general message below the button', (tester) async {
    when(
      () => bloc.state,
    ).thenReturn(const ChangeEmailFailed('Sem internet. Tente de novo.'));
    await tester.pumpWidget(harness());

    final message = find.text('Sem internet. Tente de novo.');
    expect(message, findsOneWidget);
    expect(
      tester.getTopLeft(message).dy,
      greaterThan(tester.getBottomLeft(buttonFinder).dy),
    );
    expect(
      tester.widget<TextField>(newEmailFinder).decoration?.errorText,
      isNull,
    );
    expect(
      tester.widget<TextField>(passwordFinder).decoration?.errorText,
      isNull,
    );
  });

  // A field is empty: button disabled
  testWidgets('should disable button while a field is empty', (tester) async {
    await tester.pumpWidget(harness());

    bool enabled() =>
        tester.widget<FilledButton>(buttonFinder).onPressed != null;

    expect(enabled(), isFalse);

    await tester.enterText(newEmailFinder, 'ana.lima@exemplo.com');
    await tester.pump();
    expect(enabled(), isFalse);

    await tester.enterText(newEmailFinder, '');
    await tester.enterText(passwordFinder, 'abcd1234');
    await tester.pump();
    expect(enabled(), isFalse);

    await tester.enterText(newEmailFinder, 'ana.lima@exemplo.com');
    await tester.pump();
    expect(enabled(), isTrue);
  });

  // Sending: button in loading
  testWidgets('should show busy button while in progress', (tester) async {
    when(() => bloc.state).thenReturn(const ChangeEmailInProgress());
    await tester.pumpWidget(harness());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Trocar e-mail'), findsOneWidget); // only the title
  });

  // Eye on the current password toggles visibility
  testWidgets('should toggle password visibility', (tester) async {
    await tester.pumpWidget(harness());

    bool obscured() => tester.widget<TextField>(passwordFinder).obscureText;

    expect(obscured(), isTrue);

    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pump();
    expect(obscured(), isFalse);

    await tester.tap(find.byTooltip('Esconder senha'));
    await tester.pump();
    expect(obscured(), isTrue);
  });

  testWidgets('should end the autofill context without saving on failure', (
    tester,
  ) async {
    final finishArgs = recordFinishAutofillContext(tester);
    final states = StreamController<ChangeEmailState>();
    addTearDown(states.close);
    whenListen(bloc, states.stream, initialState: const ChangeEmailIdle());
    await tester.pumpWidget(harness());
    states.add(const ChangeEmailFailed('Sem internet. Tente de novo.'));
    await tester.pump();
    expect(finishArgs, [false]);
  });

  testWidgets(
    'should end the autofill context without saving when toggling the eye',
    (tester) async {
      final finishArgs = recordFinishAutofillContext(tester);
      await tester.pumpWidget(harness());
      await tester.tap(find.byTooltip('Mostrar senha'));
      await tester.pump();
      expect(finishArgs, [false]);
    },
  );
}
