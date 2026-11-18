import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/core/ui/app_primary_button.dart';
import 'package:meu_tempo/features/auth/domain/usecases/sign_up_use_case.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/sign_up_bloc.dart';
import 'package:meu_tempo/features/auth/presentation/pages/sign_up_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockSignUpUseCase extends Mock implements SignUpUseCase {}

void main() {
  late _MockSignUpUseCase signUp;

  final checked = find.byIcon(Icons.check_circle_rounded);
  final unchecked = find.byIcon(Icons.radio_button_unchecked_rounded);

  setUpAll(() {
    registerFallbackValue(
      const SignUpParams(displayName: '', email: '', password: ''),
    );
  });

  setUp(() => signUp = _MockSignUpUseCase());

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bloc = SignUpBloc(signUp)..add(const SignUpStarted());
    addTearDown(bloc.close);
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

  Future<void> type(
    WidgetTester tester, {
    String name = 'Ana',
    String email = 'ana@exemplo.com',
    String password = 'Abcd1234',
    bool accept = true,
  }) async {
    await tester.enterText(field('Nome'), name);
    await tester.pump();
    await tester.enterText(field('E-mail'), email);
    await tester.pump();
    await tester.enterText(field('Senha'), password);
    await tester.pump();
    if (accept) {
      final box = find.byType(CheckboxListTile);
      await tester.ensureVisible(box);
      await tester.tap(box);
      await tester.pump();
    }
  }

  bool buttonEnabled(WidgetTester tester) =>
      tester
          .widget<AppPrimaryButton>(find.byType(AppPrimaryButton))
          .onPressed !=
      null;

  // REQ-012: sign-up screen just opened: button disabled, 4 rules without green
  testWidgets('should disable button and show 4 unmet rules when opened', (
    tester,
  ) async {
    await pump(tester);

    expect(buttonEnabled(tester), isFalse);
    expect(unchecked, findsNWidgets(4));
    expect(checked, findsNothing);
  });

  // REQ-012: Name "Ana", e-mail "ana@exemplo.com", password "Abcd1234", policy accepted: button active, 4 green rules
  testWidgets(
    'should enable button with 4 green rules when everything is right',
    (tester) async {
      await pump(tester);
      await type(tester);

      expect(buttonEnabled(tester), isTrue);
      expect(checked, findsNWidgets(4));
    },
  );

  // REQ-012: same data with password "abcd1234": button disabled, 3 green rules
  testWidgets(
    'should disable button with 3 green rules when password has no uppercase',
    (tester) async {
      await pump(tester);
      await type(tester, password: 'abcd1234');

      expect(buttonEnabled(tester), isFalse);
      expect(checked, findsNWidgets(3));
    },
  );

  // REQ-012: same data with the policy unchecked: button disabled, 4 green rules
  testWidgets('should disable button when policy is unchecked', (tester) async {
    await pump(tester);
    await type(tester, accept: false);

    expect(buttonEnabled(tester), isFalse);
    expect(checked, findsNWidgets(4));
  });

  // REQ-012: same data with a 72-character password: button disabled, 1 long-password warning
  testWidgets(
    'should disable button and warn long password with 72 characters',
    (tester) async {
      await pump(tester);
      await type(tester, password: 'Abcd1234' * 9);

      expect(buttonEnabled(tester), isFalse);
      expect(find.text('Use no máximo 71 caracteres.'), findsOneWidget);
    },
  );

  // REQ-012: e-mail "ana@" typed with the cursor still in the field: 0 warnings; after leaving it: 1 warning
  testWidgets('should warn email only after leaving the field', (tester) async {
    await pump(tester);
    await tester.enterText(field('E-mail'), 'ana@');
    await tester.pump();
    expect(find.text('Confira o e-mail.'), findsNothing);

    await tester.tap(field('Senha'));
    await tester.pump();
    expect(find.text('Confira o e-mail.'), findsOneWidget);
  });

  // REQ-012: tapping the enabled button adds SignUpSubmitted and calls the use case once
  testWidgets('should submit once when tapping the enabled button', (
    tester,
  ) async {
    when(() => signUp(any())).thenAnswer((_) async => const Right(unit));
    await pump(tester);
    await type(tester);

    final button = find.byType(AppPrimaryButton);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();

    verify(
      () => signUp(
        const SignUpParams(
          displayName: 'Ana',
          email: 'ana@exemplo.com',
          password: 'Abcd1234',
        ),
      ),
    ).called(1);
  });

  // REQ-012: after a server failure the screen keeps the last form, so the checklist still shows 4 green rules
  testWidgets('should keep the checklist after a server failure', (
    tester,
  ) async {
    when(
      () => signUp(any()),
    ).thenAnswer((_) async => const Left(ServerFailure()));
    await pump(tester);
    await type(tester);

    final button = find.byType(AppPrimaryButton);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text('Não foi possível criar a conta. Tente de novo.'),
      findsOneWidget,
    );
    expect(checked, findsNWidgets(4));
  });
}
