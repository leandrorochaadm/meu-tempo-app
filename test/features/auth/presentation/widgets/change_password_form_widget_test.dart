import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/core/ui/app_primary_button.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/change_password_form_bloc.dart';
import 'package:meu_tempo/features/auth/presentation/widgets/change_password_form_widget.dart';

import '../../../../helpers/autofill_test_support.dart';

void main() {
  final getIt = GetIt.instance;
  final calls = <(String, String)>[];

  setUp(() {
    calls.clear();
    getIt.registerFactory<ChangePasswordFormBloc>(ChangePasswordFormBloc.new);
  });

  tearDown(() => getIt.reset());

  Future<void> pump(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangePasswordFormWidget(
              onSubmit: (current, next) => calls.add((current, next)),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> type(WidgetTester tester, String current, String next) async {
    await tester.enterText(find.byType(TextField).at(0), current);
    await tester.enterText(find.byType(TextField).at(1), next);
    await tester.pump();
  }

  Finder button() => find.byType(AppPrimaryButton);
  bool isDisabled(WidgetTester tester) =>
      tester.widget<AppPrimaryButton>(button()).onPressed == null;

  // REQ-012: current "abcd1234", new "Wxyz5678": button active, 4 rules green, no warning
  testWidgets(
    'should enable button and show 4 met rules when current is filled and new meets REQ-003',
    (tester) async {
      await pump(tester);
      await type(tester, 'abcd1234', 'Wxyz5678');

      expect(isDisabled(tester), isFalse);
      expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(4));
      expect(find.text('É igual à senha atual.'), findsNothing);
      expect(find.text('Use no máximo 71 caracteres.'), findsNothing);
    },
  );

  // REQ-012: current empty, new "Wxyz5678": button disabled, 4 rules green, no warning
  testWidgets('should disable button when current password is empty', (
    tester,
  ) async {
    await pump(tester);
    await type(tester, '', 'Wxyz5678');

    expect(isDisabled(tester), isTrue);
    expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(4));
    expect(find.text('É igual à senha atual.'), findsNothing);
  });

  // REQ-012: current "Abcd1234", new "Abcd1234": button disabled, same password warning
  testWidgets(
    'should disable button and show same password warning when new equals current',
    (tester) async {
      await pump(tester);
      await type(tester, 'Abcd1234', 'Abcd1234');

      expect(isDisabled(tester), isTrue);
      expect(find.text('É igual à senha atual.'), findsOneWidget);
    },
  );

  // REQ-012: form just opened (both empty): button disabled, no met rule, no warning
  testWidgets('should start with button disabled, no met rule and no warning', (
    tester,
  ) async {
    await pump(tester);

    expect(isDisabled(tester), isTrue);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsNWidgets(4));
    expect(find.text('É igual à senha atual.'), findsNothing);
    expect(find.text('Use no máximo 71 caracteres.'), findsNothing);
  });

  // REQ-012: tapping the active button calls onSubmit("abcd1234", "Wxyz5678") once
  testWidgets(
    'should call onSubmit once with typed values when button is tapped',
    (tester) async {
      await pump(tester);
      await type(tester, 'abcd1234', 'Wxyz5678');

      await tester.tap(button());
      await tester.pump();

      expect(calls, [('abcd1234', 'Wxyz5678')]);
    },
  );

  // REQ-012: new password with 72 characters: button disabled, too long warning
  testWidgets(
    'should show too long warning when new password has 72 characters',
    (tester) async {
      await pump(tester);
      await type(tester, 'abcd1234', 'Aa1${'b' * 69}');

      expect(isDisabled(tester), isTrue);
      expect(find.text('Use no máximo 71 caracteres.'), findsOneWidget);
    },
  );

  Future<void> pumpWith(
    WidgetTester tester, {
    bool loading = false,
    String? currentPasswordError,
    String? newPasswordError,
  }) {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangePasswordFormWidget(
              onSubmit: (current, next) => calls.add((current, next)),
              loading: loading,
              currentPasswordError: currentPasswordError,
              newPasswordError: newPasswordError,
            ),
          ),
        ),
      ),
    );
  }

  // REQ-008: loading true with valid fields: the button is in loading
  testWidgets('should pass loading to the button', (tester) async {
    await pumpWith(tester, loading: true);
    await type(tester, 'abcd1234', 'Wxyz5678');

    expect(tester.widget<AppPrimaryButton>(button()).loading, isTrue);
  });

  // REQ-008: currentPasswordError "Senha atual incorreta." shows under the current password
  testWidgets('should show current password error from parent', (tester) async {
    await pumpWith(tester, currentPasswordError: 'Senha atual incorreta.');

    expect(
      tester
          .widget<TextField>(find.byType(TextField).at(0))
          .decoration
          ?.errorText,
      'Senha atual incorreta.',
    );
  });

  // REQ-008: local warning wins over newPasswordError ("Abcd1234" / "Abcd1234")
  testWidgets('should prefer local warning over parent new password error', (
    tester,
  ) async {
    await pumpWith(tester, newPasswordError: 'Erro de fora.');
    await type(tester, 'Abcd1234', 'Abcd1234');

    expect(find.text('É igual à senha atual.'), findsOneWidget);
    expect(find.text('Erro de fora.'), findsNothing);
  });

  testWidgets(
    'should end the autofill context without saving when toggling each eye',
    (tester) async {
      final finishArgs = recordFinishAutofillContext(tester);
      await pump(tester);
      await tester.tap(find.byTooltip('Mostrar senha').at(0));
      await tester.pump();
      await tester.tap(find.byTooltip('Mostrar senha').first);
      await tester.pump();
      expect(finishArgs, [false, false]);
    },
  );
}
