import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/auth/domain/entities/user_entity.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_tempo/features/lock_screen/presentation/bloc/lock_screen_sync_bloc.dart';
import 'package:meu_tempo/features/lock_screen/presentation/widgets/lock_screen_sync_listener.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockLockScreenSyncBloc
    extends MockBloc<LockScreenSyncEvent, LockScreenSyncState>
    implements LockScreenSyncBloc {}

const _user = UserEntity(uid: 'u1', email: 'a@b.com');

void main() {
  late _MockAuthBloc authBloc;
  late _MockLockScreenSyncBloc syncBloc;

  setUpAll(() => registerFallbackValue(const LockScreenSyncStarted()));

  setUp(() {
    authBloc = _MockAuthBloc();
    syncBloc = _MockLockScreenSyncBloc();
  });

  Widget harness() => MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>.value(value: authBloc),
      BlocProvider<LockScreenSyncBloc>.value(value: syncBloc),
    ],
    child: const LockScreenSyncListener(child: SizedBox.shrink()),
  );

  Future<void> setLifecycle(
    WidgetTester tester,
    AppLifecycleState state,
  ) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.lifecycle.name,
      SystemChannels.lifecycle.codec.encodeMessage(state.toString()),
      (_) {},
    );
    await tester.pump();
  }

  Future<void> goToBackground(WidgetTester tester) async {
    await setLifecycle(tester, AppLifecycleState.inactive);
    await setLifecycle(tester, AppLifecycleState.hidden);
    await setLifecycle(tester, AppLifecycleState.paused);
  }

  Future<void> backToForeground(WidgetTester tester) async {
    await setLifecycle(tester, AppLifecycleState.hidden);
    await setLifecycle(tester, AppLifecycleState.inactive);
    await setLifecycle(tester, AppLifecycleState.resumed);
  }

  testWidgets('signed in on mount: starts mirroring', (tester) async {
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthAuthenticated(_user),
    );

    await tester.pumpWidget(harness());

    verify(() => syncBloc.add(const LockScreenSyncStarted())).called(1);
  });

  testWidgets('signed out on mount: clears the lock screen', (tester) async {
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthUnauthenticated(),
    );

    await tester.pumpWidget(harness());

    verify(() => syncBloc.add(const LockScreenSyncSignedOut())).called(1);
  });

  testWidgets('session still resolving: does nothing', (tester) async {
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthInitial(),
    );

    await tester.pumpWidget(harness());

    verifyNever(() => syncBloc.add(any()));
  });

  testWidgets('signed in: starts mirroring', (tester) async {
    whenListen(
      authBloc,
      Stream<AuthState>.value(const AuthAuthenticated(_user)),
      initialState: const AuthInitial(),
    );

    await tester.pumpWidget(harness());
    await tester.pump();

    verify(() => syncBloc.add(const LockScreenSyncStarted())).called(1);
  });

  testWidgets('signed out: clears the lock screen', (tester) async {
    whenListen(
      authBloc,
      Stream<AuthState>.value(const AuthUnauthenticated()),
      initialState: const AuthAuthenticated(_user),
    );

    await tester.pumpWidget(harness());
    await tester.pump();

    verify(() => syncBloc.add(const LockScreenSyncStarted())).called(1);
    verify(() => syncBloc.add(const LockScreenSyncSignedOut())).called(1);
  });

  testWidgets('error on sign-out does not stop mirroring', (tester) async {
    whenListen(
      authBloc,
      Stream<AuthState>.value(const AuthError('x')),
      initialState: const AuthAuthenticated(_user),
    );

    await tester.pumpWidget(harness());
    await tester.pump();

    verifyNever(() => syncBloc.add(const LockScreenSyncSignedOut()));
  });

  testWidgets('sign-in in progress dispatches nothing', (tester) async {
    whenListen(
      authBloc,
      Stream<AuthState>.value(const AuthLoading()),
      initialState: const AuthUnauthenticated(),
    );

    await tester.pumpWidget(harness());
    await tester.pump();

    verify(() => syncBloc.add(const LockScreenSyncSignedOut())).called(1);
    verifyNever(() => syncBloc.add(const LockScreenSyncStarted()));
  });

  testWidgets('returning to the foreground reconciles', (tester) async {
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthAuthenticated(_user),
    );

    await tester.pumpWidget(harness());
    await goToBackground(tester);
    await backToForeground(tester);

    verify(() => syncBloc.add(const LockScreenSyncAppResumed())).called(1);
  });

  testWidgets('going to the background dispatches nothing', (tester) async {
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthAuthenticated(_user),
    );

    await tester.pumpWidget(harness());
    await goToBackground(tester);

    verifyNever(() => syncBloc.add(const LockScreenSyncAppResumed()));

    // Unmount first so restoring "resumed" does not fire the event.
    await tester.pumpWidget(const SizedBox.shrink());
    await backToForeground(tester);
  });

  testWidgets('unmounting disposes the lifecycle listener', (tester) async {
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthAuthenticated(_user),
    );

    await tester.pumpWidget(harness());
    await tester.pumpWidget(const SizedBox.shrink());
    await goToBackground(tester);
    await backToForeground(tester);

    verifyNever(() => syncBloc.add(const LockScreenSyncAppResumed()));
  });
}
