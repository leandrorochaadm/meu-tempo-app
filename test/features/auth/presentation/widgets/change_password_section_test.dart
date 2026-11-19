import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/di/injection.dart';
import 'package:meu_tempo/core/error/account_field_error_enum.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/change_password_bloc.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/change_password_form_bloc.dart';
import 'package:meu_tempo/features/auth/presentation/widgets/change_password_section.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/autofill_test_support.dart';

class _MockChangePasswordBloc
    extends MockBloc<ChangePasswordEvent, ChangePasswordState>
    implements ChangePasswordBloc {}

void main() {
  late _MockChangePasswordBloc bloc;

  setUpAll(
    () => registerFallbackValue(
      const ChangePasswordSubmitted(currentPassword: 'x', newPassword: 'y'),
    ),
  );

  setUp(() {
    bloc = _MockChangePasswordBloc();
    when(() => bloc.state).thenReturn(const ChangePasswordIdle());
    getIt.registerFactory<ChangePasswordBloc>(() => bloc);
    getIt.registerFactory<ChangePasswordFormBloc>(ChangePasswordFormBloc.new);
  });

  tearDown(() {
    getIt.unregister<ChangePasswordBloc>();
    getIt.unregister<ChangePasswordFormBloc>();
  });

  Future<void> pump(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: SingleChildScrollView(child: ChangePasswordSection()),
        ),
      ),
    );
  }

  final currentFinder = find.byType(TextField).at(0);
  final newFinder = find.byType(TextField).at(1);
  final buttonFinder = find.widgetWithText(FilledButton, 'Trocar senha');

  Future<void> fillBoth(WidgetTester tester) async {
    await tester.enterText(currentFinder, 'abcd1234');
    await tester.enterText(newFinder, 'Wxyz5678');
    await tester.pump();
  }

  // REQ-008: types "abcd1234" / "Wxyz5678" and taps "Trocar senha": ChangePasswordSubmitted once with both texts
  testWidgets('should submit typed passwords when button is tapped', (
    tester,
  ) async {
    await pump(tester);

    await fillBoth(tester);
    await tester.tap(buttonFinder);
    await tester.pump();

    verify(
      () => bloc.add(
        const ChangePasswordSubmitted(
          currentPassword: 'abcd1234',
          newPassword: 'Wxyz5678',
        ),
      ),
    ).called(1);
  });

  // REQ-008: state Failed('Senha atual incorreta.', field: currentPassword): message under the current password
  testWidgets(
    'should show wrong current password message under current password',
    (tester) async {
      when(() => bloc.state).thenReturn(
        const ChangePasswordFailed(
          'Senha atual incorreta.',
          field: ChangePasswordFieldEnum.currentPassword,
        ),
      );
      await pump(tester);

      expect(
        tester.widget<TextField>(currentFinder).decoration?.errorText,
        'Senha atual incorreta.',
      );
      expect(tester.widget<TextField>(newFinder).decoration?.errorText, isNull);
    },
  );

  // REQ-008: state Invalid([samePassword]) with empty fields: "É igual à senha atual." under the new password
  testWidgets('should show field warning under new password when invalid', (
    tester,
  ) async {
    when(
      () => bloc.state,
    ).thenReturn(ChangePasswordInvalid([AccountFieldErrorEnum.samePassword]));
    await pump(tester);

    expect(
      tester.widget<TextField>(newFinder).decoration?.errorText,
      'É igual à senha atual.',
    );
  });

  // Offline: general message below the button, on no field
  testWidgets('should show general message below the button', (tester) async {
    when(
      () => bloc.state,
    ).thenReturn(const ChangePasswordFailed('Sem internet. Tente de novo.'));
    await pump(tester);

    final message = find.text('Sem internet. Tente de novo.');
    expect(message, findsOneWidget);
    expect(
      tester.getTopLeft(message).dy,
      greaterThan(tester.getBottomLeft(buttonFinder).dy),
    );
    expect(
      tester.widget<TextField>(currentFinder).decoration?.errorText,
      isNull,
    );
    expect(tester.widget<TextField>(newFinder).decoration?.errorText, isNull);
  });

  // Sending: button in loading
  testWidgets('should show busy button while in progress', (tester) async {
    when(() => bloc.state).thenReturn(const ChangePasswordInProgress());
    await pump(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Trocar senha'), findsOneWidget); // only the title
  });

  // REQ-008: success (Idle to Done) after typing: fields cleared, "Senha trocada." shown, no navigation
  testWidgets('should clear fields and show "Senha trocada." on success', (
    tester,
  ) async {
    final states = StreamController<ChangePasswordState>();
    addTearDown(states.close);
    whenListen(bloc, states.stream, initialState: const ChangePasswordIdle());
    await pump(tester);
    await fillBoth(tester);

    states.add(const ChangePasswordDone());
    await tester.pump();
    await tester.pump();

    expect(find.text('Senha trocada.'), findsOneWidget);
    expect(tester.widget<TextField>(currentFinder).controller?.text, isEmpty);
    expect(tester.widget<TextField>(newFinder).controller?.text, isEmpty);
    expect(find.byType(ChangePasswordSection), findsOneWidget);
  });

  // Empty fields (existing rule): button disabled, nothing sent
  testWidgets('should keep button disabled when fields are empty', (
    tester,
  ) async {
    await pump(tester);

    expect(tester.widget<FilledButton>(buttonFinder).onPressed, isNull);

    await tester.tap(buttonFinder, warnIfMissed: false);
    await tester.pump();

    verifyNever(() => bloc.add(any()));
  });

  testWidgets('should end the autofill context without saving on failure', (
    tester,
  ) async {
    final finishArgs = recordFinishAutofillContext(tester);
    final states = StreamController<ChangePasswordState>();
    addTearDown(states.close);
    whenListen(bloc, states.stream, initialState: const ChangePasswordIdle());
    await pump(tester);
    states.add(const ChangePasswordFailed('Sem internet. Tente de novo.'));
    await tester.pump();
    states.add(ChangePasswordInvalid([AccountFieldErrorEnum.samePassword]));
    await tester.pump();
    expect(finishArgs, [false, false]);
  });
}
