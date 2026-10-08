import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_tempo/core/router/routes.dart';
import 'package:meu_tempo/features/auth/domain/entities/user_entity.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_tap_entity.dart';
import 'package:meu_tempo/features/lock_screen/presentation/bloc/lock_screen_tap_bloc.dart';
import 'package:meu_tempo/features/lock_screen/presentation/widgets/lock_screen_tap_navigator.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockTapBloc extends MockBloc<LockScreenTapEvent, LockScreenTapState>
    implements LockScreenTapBloc {}

const _user = UserEntity(uid: 'u1', email: 'a@b.com');
const taskTap = LockScreenTapEntity(
  targetId: 't1',
  targetType: TimerTargetTypeEnum.task,
);
const appointmentTap = LockScreenTapEntity(
  targetId: 'a1',
  targetType: TimerTargetTypeEnum.appointment,
);

void main() {
  late _MockAuthBloc authBloc;
  late _MockTapBloc bloc;

  setUpAll(() => registerFallbackValue(const LockScreenTapStarted()));

  setUp(() {
    authBloc = _MockAuthBloc();
    bloc = _MockTapBloc();
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthAuthenticated(_user),
    );
  });

  Widget harness() {
    final router = GoRouter(
      initialLocation: Routes.home,
      routes: [
        ShellRoute(
          builder: (_, _, child) => LockScreenTapNavigator(child: child),
          routes: [
            GoRoute(
              path: Routes.home,
              builder: (_, _) => const Scaffold(body: Text('home')),
            ),
            GoRoute(
              path: Routes.timerTarget,
              builder: (_, state) =>
                  Scaffold(body: Text('alvo ${state.uri.query}')),
            ),
          ],
        ),
      ],
    );
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<LockScreenTapBloc>.value(value: bloc),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('task tap opens the target route', (tester) async {
    whenListen(
      bloc,
      Stream<LockScreenTapState>.value(const LockScreenTapPending(taskTap)),
      initialState: const LockScreenTapIdle(),
    );

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('alvo type=task&id=t1'), findsOneWidget);
    verify(() => bloc.add(const LockScreenTapHandled(taskTap)));
  });

  testWidgets('appointment tap opens the target route', (tester) async {
    whenListen(
      bloc,
      Stream<LockScreenTapState>.value(
        const LockScreenTapPending(appointmentTap),
      ),
      initialState: const LockScreenTapIdle(),
    );

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('alvo type=appointment&id=a1'), findsOneWidget);
  });

  testWidgets('tap pending on mount (app opened by the tap)', (tester) async {
    whenListen(
      bloc,
      const Stream<LockScreenTapState>.empty(),
      initialState: const LockScreenTapPending(taskTap),
    );

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('alvo type=task&id=t1'), findsOneWidget);
  });

  testWidgets('no tap does not navigate', (tester) async {
    whenListen(
      bloc,
      const Stream<LockScreenTapState>.empty(),
      initialState: const LockScreenTapIdle(),
    );

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('tap with the login resolving waits for the session', (
    tester,
  ) async {
    final authController = StreamController<AuthState>();
    addTearDown(authController.close);
    whenListen(
      authBloc,
      authController.stream,
      initialState: const AuthInitial(),
    );
    whenListen(
      bloc,
      const Stream<LockScreenTapState>.empty(),
      initialState: const LockScreenTapPending(taskTap),
    );

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    verifyNever(() => bloc.add(any()));

    authController.add(const AuthAuthenticated(_user));
    await tester.pumpAndSettle();

    expect(find.text('alvo type=task&id=t1'), findsOneWidget);
    verify(() => bloc.add(const LockScreenTapHandled(taskTap))).called(1);
  });

  testWidgets('signed out does not open', (tester) async {
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthUnauthenticated(),
    );
    whenListen(
      bloc,
      const Stream<LockScreenTapState>.empty(),
      initialState: const LockScreenTapPending(taskTap),
    );

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });
}
