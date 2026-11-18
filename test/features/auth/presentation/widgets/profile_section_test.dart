import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/di/injection.dart';
import 'package:meu_tempo/core/error/account_field_error_enum.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/auth/domain/entities/user_entity.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/update_display_name_bloc.dart';
import 'package:meu_tempo/features/auth/presentation/widgets/profile_section.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockUpdateDisplayNameBloc
    extends MockBloc<UpdateDisplayNameEvent, UpdateDisplayNameState>
    implements UpdateDisplayNameBloc {}

void main() {
  late _MockAuthBloc authBloc;
  late _MockUpdateDisplayNameBloc bloc;

  setUpAll(() => registerFallbackValue(const UpdateDisplayNameSubmitted('x')));

  setUp(() {
    authBloc = _MockAuthBloc();
    bloc = _MockUpdateDisplayNameBloc();
    when(() => bloc.state).thenReturn(const UpdateDisplayNameIdle());
    getIt.registerFactory<UpdateDisplayNameBloc>(() => bloc);
  });

  tearDown(() => getIt.unregister<UpdateDisplayNameBloc>());

  void signedInAs(String? displayName) {
    when(() => authBloc.state).thenReturn(
      AuthAuthenticated(
        UserEntity(
          uid: 'u1',
          email: 'ana@exemplo.com',
          displayName: displayName,
        ),
      ),
    );
  }

  Widget harness() => MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: const ProfileSection(),
      ),
    ),
  );

  TextField nameField(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField));

  // REQ-006: account without Name opens the Perfil: 1 empty field with "Informe seu nome"
  testWidgets(
    'should show empty name field with hint when account has no name',
    (tester) async {
      signedInAs(null);
      await tester.pumpWidget(harness());

      expect(find.byType(TextField), findsOneWidget);
      expect(nameField(tester).controller?.text, isEmpty);
      expect(nameField(tester).decoration?.hintText, 'Informe seu nome');
    },
  );

  // REQ-006: account with Name "Ana" opens the Perfil: field filled with "Ana"
  testWidgets('should fill name field with current name', (tester) async {
    signedInAs('Ana');
    await tester.pumpWidget(harness());

    expect(nameField(tester).controller?.text, 'Ana');
  });

  // REQ-006: tapping "Salvar" sends the typed text as is
  testWidgets('should submit typed name when save is tapped', (tester) async {
    signedInAs('Ana');
    await tester.pumpWidget(harness());

    await tester.enterText(find.byType(TextField), ' Ana Lima ');
    await tester.tap(find.text('Salvar'));
    await tester.pump();

    verify(
      () => bloc.add(const UpdateDisplayNameSubmitted(' Ana Lima ')),
    ).called(1);
  });

  // REQ-006: Invalid([sameDisplayName]): "Esse já é o seu nome." under the field
  testWidgets('should show "Esse já é o seu nome." under the field', (
    tester,
  ) async {
    signedInAs('Ana');
    when(() => bloc.state).thenReturn(
      UpdateDisplayNameInvalid([AccountFieldErrorEnum.sameDisplayName]),
    );
    await tester.pumpWidget(harness());

    expect(find.text('Esse já é o seu nome.'), findsOneWidget);
  });

  // REQ-006: Failed: the message shows under the field
  testWidgets('should show failure message under the field', (tester) async {
    signedInAs('Ana');
    when(
      () => bloc.state,
    ).thenReturn(const UpdateDisplayNameFailed('Sem internet. Tente de novo.'));
    await tester.pumpWidget(harness());

    expect(find.text('Sem internet. Tente de novo.'), findsOneWidget);
  });

  // REQ-006: InProgress: save button in loading
  testWidgets('should show busy button while in progress', (tester) async {
    signedInAs('Ana');
    when(() => bloc.state).thenReturn(const UpdateDisplayNameInProgress());
    await tester.pumpWidget(harness());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Salvar'), findsNothing);
  });

  // REQ-006: Saved: "Nome salvo." shows
  testWidgets('should show "Nome salvo." when name is saved', (tester) async {
    signedInAs('Ana');
    whenListen(
      bloc,
      Stream<UpdateDisplayNameState>.fromIterable([
        const UpdateDisplayNameSaved(),
      ]),
      initialState: const UpdateDisplayNameIdle(),
    );
    await tester.pumpWidget(harness());
    await tester.pump();

    expect(find.text('Nome salvo.'), findsOneWidget);
  });

  // REQ-006: saved name " Ana Lima " arrives trimmed from AuthBloc: field shows "Ana Lima"
  testWidgets('should show the name from AuthBloc after saving', (
    tester,
  ) async {
    signedInAs('Ana');
    whenListen(
      authBloc,
      Stream<AuthState>.fromIterable([
        const AuthAuthenticated(
          UserEntity(
            uid: 'u1',
            email: 'ana@exemplo.com',
            displayName: 'Ana Lima',
          ),
        ),
      ]),
      initialState: AuthAuthenticated(
        const UserEntity(
          uid: 'u1',
          email: 'ana@exemplo.com',
          displayName: 'Ana',
        ),
      ),
    );
    await tester.pumpWidget(harness());
    await tester.pump();

    expect(nameField(tester).controller?.text, 'Ana Lima');
  });
}
