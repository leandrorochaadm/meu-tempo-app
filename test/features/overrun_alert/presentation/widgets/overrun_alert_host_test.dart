import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/auth/domain/entities/user_entity.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_tempo/features/overrun_alert/domain/entities/overrun_alert_entity.dart';
import 'package:meu_tempo/features/overrun_alert/presentation/bloc/overrun_alert_bloc.dart';
import 'package:meu_tempo/features/overrun_alert/presentation/widgets/overrun_alert_host.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockOverrunBloc extends MockBloc<OverrunAlertEvent, OverrunAlertState>
    implements OverrunAlertBloc {}

const _user = UserEntity(uid: 'u1', email: 'a@b.com');
const _message = '“Tela de login” passou do tempo estimado.';

void main() {
  late _MockAuthBloc authBloc;
  late _MockOverrunBloc bloc;
  late StreamController<OverrunAlertState> states;
  late ValueNotifier<bool> show;

  final alert = OverrunAlertEntity(
    targetId: 't1',
    title: 'Tela de login',
    alertAt: DateTime(2026, 10, 7, 10, 30),
  );

  setUpAll(() => registerFallbackValue(const OverrunAlertStarted()));

  setUp(() {
    authBloc = _MockAuthBloc();
    bloc = _MockOverrunBloc();
    states = StreamController<OverrunAlertState>.broadcast();
    show = ValueNotifier(true);
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthAuthenticated(_user),
    );
    whenListen(bloc, states.stream, initialState: const OverrunAlertHidden());
  });

  tearDown(() async {
    await states.close();
    show.dispose();
  });

  Widget harness() => MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>.value(value: authBloc),
      BlocProvider<OverrunAlertBloc>.value(value: bloc),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: ValueListenableBuilder<bool>(
          valueListenable: show,
          builder: (_, visible, _) => visible
              ? const OverrunAlertHost(child: SizedBox.shrink())
              : const SizedBox.shrink(),
        ),
      ),
    ),
  );

  Future<void> emit(WidgetTester tester, OverrunAlertState state) async {
    states.add(state);
    await tester.pumpAndSettle();
  }

  testWidgets('should start when authenticated at mount', (tester) async {
    await tester.pumpWidget(harness());
    verify(() => bloc.add(const OverrunAlertStarted())).called(1);
  });

  testWidgets('should sign out when auth becomes unauthenticated', (
    tester,
  ) async {
    final authStates = StreamController<AuthState>();
    addTearDown(authStates.close);
    whenListen(
      authBloc,
      authStates.stream,
      initialState: const AuthAuthenticated(_user),
    );
    await tester.pumpWidget(harness());
    authStates.add(const AuthUnauthenticated());
    await tester.pump();
    verify(() => bloc.add(const OverrunAlertSignedOut())).called(1);
  });

  testWidgets('should do nothing while auth is loading', (tester) async {
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthLoading(),
    );
    await tester.pumpWidget(harness());
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('should show banner with task title', (tester) async {
    await tester.pumpWidget(harness());
    await emit(tester, OverrunAlertVisible(alert));
    expect(find.text(_message), findsOneWidget);
    expect(find.text('Pausar'), findsOneWidget);
    expect(find.text('Agora não'), findsOneWidget);
  });

  testWidgets('should request pause on Pausar', (tester) async {
    await tester.pumpWidget(harness());
    await emit(tester, OverrunAlertVisible(alert));
    await tester.tap(find.text('Pausar'));
    verify(() => bloc.add(const OverrunAlertPauseRequested())).called(1);
  });

  testWidgets('should dismiss on Agora não', (tester) async {
    await tester.pumpWidget(harness());
    await emit(tester, OverrunAlertVisible(alert));
    await tester.tap(find.text('Agora não'));
    verify(() => bloc.add(const OverrunAlertDismissed())).called(1);
  });

  testWidgets('should hide banner on Hidden', (tester) async {
    await tester.pumpWidget(harness());
    await emit(tester, OverrunAlertVisible(alert));
    await emit(tester, const OverrunAlertHidden());
    expect(find.text(_message), findsNothing);
  });

  testWidgets('should show snackbar and keep banner on PauseFailed', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await emit(tester, OverrunAlertVisible(alert));
    await emit(tester, OverrunAlertPauseFailed(alert, 'Sem conexão.'));
    expect(find.text('Sem conexão.'), findsOneWidget);
    expect(find.text(_message), findsOneWidget);
  });

  testWidgets('should remove banner when unmounted', (tester) async {
    await tester.pumpWidget(harness());
    await emit(tester, OverrunAlertVisible(alert));
    expect(find.text(_message), findsOneWidget);
    show.value = false;
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(_message), findsNothing);
  });
}
