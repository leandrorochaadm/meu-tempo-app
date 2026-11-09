import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/di/injection.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/delete_account_bloc.dart';
import 'package:meu_tempo/features/auth/presentation/widgets/delete_account_section.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeleteAccountBloc
    extends MockBloc<DeleteAccountEvent, DeleteAccountState>
    implements DeleteAccountBloc {}

void main() {
  late _MockDeleteAccountBloc bloc;

  setUpAll(() => registerFallbackValue(const DeleteAccountRequested()));

  setUp(() {
    bloc = _MockDeleteAccountBloc();
    when(() => bloc.state).thenReturn(const DeleteAccountIdle());
    getIt.registerFactory<DeleteAccountBloc>(() => bloc);
  });

  tearDown(() => getIt.unregister<DeleteAccountBloc>());

  Widget harness() => MaterialApp(
    theme: AppTheme.dark,
    home: const Scaffold(body: DeleteAccountSection()),
  );

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('Excluir conta'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir conta?'), findsOneWidget);
  }

  testWidgets('should not request deletion when dialog is cancelled', (
    tester,
  ) async {
    await openDialog(tester);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Excluir conta?'), findsNothing);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('should request deletion when dialog is confirmed', (
    tester,
  ) async {
    await openDialog(tester);
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    verify(() => bloc.add(const DeleteAccountRequested())).called(1);
  });

  testWidgets('should show busy button while in progress', (tester) async {
    when(() => bloc.state).thenReturn(const DeleteAccountInProgress());
    await tester.pumpWidget(harness());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Excluir conta'), findsNothing);
  });

  testWidgets('should show failure message when state is failed', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(
      const DeleteAccountFailed('Sem conexão. Verifique a internet.'),
    );
    await tester.pumpWidget(harness());

    expect(find.text('Sem conexão. Verifique a internet.'), findsOneWidget);
  });
}
