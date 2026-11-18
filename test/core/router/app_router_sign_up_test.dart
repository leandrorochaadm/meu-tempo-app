import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/di/injection.dart';
import 'package:meu_tempo/core/router/app_router.dart';
import 'package:meu_tempo/core/router/routes.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/appointment/presentation/bloc/agenda_bloc.dart';
import 'package:meu_tempo/features/auth/domain/entities/user_entity.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/sign_up_bloc.dart';
import 'package:meu_tempo/features/auth/presentation/pages/login_page.dart';
import 'package:meu_tempo/features/auth/presentation/pages/sign_up_page.dart';
import 'package:meu_tempo/features/lock_screen/presentation/bloc/lock_screen_permission_bloc.dart';
import 'package:meu_tempo/features/lock_screen/presentation/bloc/lock_screen_tap_bloc.dart';
import 'package:meu_tempo/features/overrun_alert/presentation/bloc/overrun_alert_bloc.dart';
import 'package:meu_tempo/features/task/presentation/bloc/active_timer_bloc.dart';
import 'package:meu_tempo/features/task/presentation/bloc/task_list_bloc.dart';
import 'package:meu_tempo/features/task/presentation/pages/task_list_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockOverrunAlertBloc
    extends MockBloc<OverrunAlertEvent, OverrunAlertState>
    implements OverrunAlertBloc {}

class _MockActiveTimerBloc extends MockBloc<ActiveTimerEvent, ActiveTimerState>
    implements ActiveTimerBloc {}

class _MockPermissionBloc
    extends MockBloc<LockScreenPermissionEvent, LockScreenPermissionState>
    implements LockScreenPermissionBloc {}

class _MockTapBloc extends MockBloc<LockScreenTapEvent, LockScreenTapState>
    implements LockScreenTapBloc {}

class _MockTaskListBloc extends MockBloc<TaskListEvent, TaskListState>
    implements TaskListBloc {}

class _MockAgendaBloc extends MockBloc<AgendaEvent, AgendaState>
    implements AgendaBloc {}

class _MockSignUpBloc extends MockBloc<SignUpEvent, SignUpState>
    implements SignUpBloc {}

void main() {
  late _MockAuthBloc authBloc;
  late _MockActiveTimerBloc timerBloc;
  late _MockPermissionBloc permissionBloc;
  late _MockTapBloc tapBloc;
  late _MockOverrunAlertBloc overrunBloc;
  late AppRouter appRouter;

  void setSession(AuthState state) {
    whenListen(authBloc, const Stream<AuthState>.empty(), initialState: state);
  }

  setUp(() {
    authBloc = _MockAuthBloc();
    timerBloc = _MockActiveTimerBloc();
    permissionBloc = _MockPermissionBloc();
    tapBloc = _MockTapBloc();
    overrunBloc = _MockOverrunAlertBloc();
    when(() => overrunBloc.state).thenReturn(const OverrunAlertHidden());
    final taskListBloc = _MockTaskListBloc();
    final agendaBloc = _MockAgendaBloc();
    final signUpBloc = _MockSignUpBloc();

    when(() => timerBloc.state).thenReturn(const ActiveTimerHidden());
    when(
      () => permissionBloc.state,
    ).thenReturn(const LockScreenPermissionBannerHidden());
    when(() => tapBloc.state).thenReturn(const LockScreenTapIdle());
    when(() => taskListBloc.state).thenReturn(const TaskListLoading());
    when(() => agendaBloc.state).thenReturn(const AgendaLoading());
    when(() => signUpBloc.state).thenReturn(const SignUpIdle());

    getIt
      ..registerFactory<TaskListBloc>(() => taskListBloc)
      ..registerFactory<AgendaBloc>(() => agendaBloc)
      ..registerFactory<SignUpBloc>(() => signUpBloc);
  });

  tearDown(() async => getIt.reset());

  Future<void> open(WidgetTester tester, String location) async {
    appRouter = AppRouter(authBloc);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<ActiveTimerBloc>.value(value: timerBloc),
          BlocProvider<LockScreenPermissionBloc>.value(value: permissionBloc),
          BlocProvider<LockScreenTapBloc>.value(value: tapBloc),
          BlocProvider<OverrunAlertBloc>.value(value: overrunBloc),
        ],
        child: MaterialApp.router(
          theme: AppTheme.dark,
          routerConfig: appRouter.router,
        ),
      ),
    );
    await tester.pump();
    appRouter.router.go(location);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  const signedIn = AuthAuthenticated(
    UserEntity(uid: 'u1', email: 'ana@exemplo.com'),
  );

  // REQ-001: without a session, the sign-up route opens the sign-up screen
  testWidgets('should open sign-up without a session', (tester) async {
    setSession(const AuthUnauthenticated());
    await open(tester, Routes.signUp);

    expect(find.byType(SignUpPage), findsOneWidget);
  });

  // REQ-001: without a session, a private route sends to the login screen
  testWidgets('should send to login when signed out outside public routes', (
    tester,
  ) async {
    setSession(const AuthUnauthenticated());
    await open(tester, Routes.home);

    expect(find.byType(LoginPage), findsOneWidget);
  });

  // REQ-001: with a session (including right after sign-up), the sign-up route goes to the task list
  testWidgets('should send to home when signed in on sign-up', (tester) async {
    setSession(signedIn);
    await open(tester, Routes.signUp);

    expect(find.byType(TaskListPage), findsOneWidget);
    expect(find.byType(SignUpPage), findsNothing);
  });

  // REQ-001: with a session, the login route still goes to the task list
  testWidgets('should send to home when signed in on login', (tester) async {
    setSession(signedIn);
    await open(tester, Routes.login);

    expect(find.byType(TaskListPage), findsOneWidget);
  });
}
