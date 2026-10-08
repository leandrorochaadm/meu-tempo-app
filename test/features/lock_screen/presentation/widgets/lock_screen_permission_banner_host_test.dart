import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/auth/domain/entities/user_entity.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_tempo/features/lock_screen/presentation/bloc/lock_screen_permission_bloc.dart';
import 'package:meu_tempo/features/lock_screen/presentation/widgets/lock_screen_permission_banner_host.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockPermissionBloc
    extends MockBloc<LockScreenPermissionEvent, LockScreenPermissionState>
    implements LockScreenPermissionBloc {}

const _user = UserEntity(uid: 'u1', email: 'a@b.com');
const _message =
    'Ative os avisos para ver o cronômetro com o celular bloqueado';

void main() {
  late _MockAuthBloc authBloc;
  late _MockPermissionBloc bloc;
  late ValueNotifier<bool> show;

  setUpAll(() => registerFallbackValue(const LockScreenPermissionStarted()));

  setUp(() {
    authBloc = _MockAuthBloc();
    bloc = _MockPermissionBloc();
    show = ValueNotifier(true);
    whenListen(authBloc, const Stream<AuthState>.empty(),
        initialState: const AuthAuthenticated(_user));
    whenListen(bloc, const Stream<LockScreenPermissionState>.empty(),
        initialState: const LockScreenPermissionBannerHidden());
  });

  tearDown(() => show.dispose());

  Widget harness() => MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<LockScreenPermissionBloc>.value(value: bloc),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: show,
              builder: (_, visible, _) => visible
                  ? const LockScreenPermissionBannerHost(
                      child: SizedBox.shrink(),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      );

  Future<void> setLifecycle(WidgetTester tester, AppLifecycleState state) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.lifecycle.name,
      SystemChannels.lifecycle.codec.encodeMessage(state.toString()),
      (_) {},
    );
    await tester.pump();
  }

  void showBannerOnStart() => whenListen(
        bloc,
        Stream<LockScreenPermissionState>.value(
          const LockScreenPermissionBannerVisible(),
        ),
        initialState: const LockScreenPermissionBannerHidden(),
      );

  testWidgets('signed in on mount: starts watching', (tester) async {
    await tester.pumpWidget(harness());

    verify(() => bloc.add(const LockScreenPermissionStarted())).called(1);
  });

  testWidgets('login resolving does not watch; watches on sign-in',
      (tester) async {
    final authController = StreamController<AuthState>();
    addTearDown(authController.close);
    whenListen(authBloc, authController.stream,
        initialState: const AuthInitial());

    await tester.pumpWidget(harness());
    await tester.pump();
    verifyNever(() => bloc.add(const LockScreenPermissionStarted()));

    authController.add(const AuthAuthenticated(_user));
    await tester.pump();
    verify(() => bloc.add(const LockScreenPermissionStarted())).called(1);
  });

  testWidgets('signed out does not watch', (tester) async {
    whenListen(authBloc, const Stream<AuthState>.empty(),
        initialState: const AuthUnauthenticated());

    await tester.pumpWidget(harness());

    verifyNever(() => bloc.add(const LockScreenPermissionStarted()));
  });

  testWidgets('signing out stops watching', (tester) async {
    whenListen(authBloc, Stream<AuthState>.value(const AuthUnauthenticated()),
        initialState: const AuthAuthenticated(_user));

    await tester.pumpWidget(harness());
    await tester.pump();

    verify(() => bloc.add(const LockScreenPermissionStopped()));
  });

  testWidgets('visible banner shows the text and the buttons', (tester) async {
    showBannerOnStart();

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text(_message), findsOneWidget);
    expect(find.text('Abrir Ajustes'), findsOneWidget);
    expect(find.text('Agora não'), findsOneWidget);
  });

  testWidgets('"Abrir Ajustes" asks for the settings', (tester) async {
    showBannerOnStart();
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abrir Ajustes'));

    verify(() => bloc.add(const LockScreenPermissionSettingsRequested()))
        .called(1);
  });

  testWidgets('"Agora não" dismisses', (tester) async {
    showBannerOnStart();
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agora não'));

    verify(() => bloc.add(const LockScreenPermissionBannerDismissed()))
        .called(1);
  });

  testWidgets('hidden after visible removes the banner', (tester) async {
    whenListen(
      bloc,
      Stream<LockScreenPermissionState>.fromIterable(const [
        LockScreenPermissionBannerVisible(),
        LockScreenPermissionBannerHidden(),
      ]),
      initialState: const LockScreenPermissionBannerHidden(),
    );

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text(_message), findsNothing);
  });

  testWidgets('back to the foreground reevaluates', (tester) async {
    await tester.pumpWidget(harness());

    await setLifecycle(tester, AppLifecycleState.inactive);
    await setLifecycle(tester, AppLifecycleState.hidden);
    await setLifecycle(tester, AppLifecycleState.paused);
    await setLifecycle(tester, AppLifecycleState.hidden);
    await setLifecycle(tester, AppLifecycleState.inactive);
    await setLifecycle(tester, AppLifecycleState.resumed);

    verify(() => bloc.add(const LockScreenPermissionAppResumed())).called(1);
  });

  testWidgets('unmounting stops watching and removes the banner',
      (tester) async {
    showBannerOnStart();
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    expect(find.text(_message), findsOneWidget);

    show.value = false;
    await tester.pump();
    await tester.pumpAndSettle();

    verify(() => bloc.add(const LockScreenPermissionStopped())).called(1);
    expect(find.text(_message), findsNothing);
  });
}
