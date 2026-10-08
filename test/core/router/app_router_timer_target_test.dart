import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/di/injection.dart';
import 'package:meu_tempo/core/router/app_router.dart';
import 'package:meu_tempo/core/router/routes.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/appointment/presentation/bloc/agenda_bloc.dart';
import 'package:meu_tempo/features/appointment/presentation/pages/agenda_page.dart';
import 'package:meu_tempo/features/auth/domain/entities/user_entity.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_tempo/features/lock_screen/presentation/bloc/lock_screen_permission_bloc.dart';
import 'package:meu_tempo/features/lock_screen/presentation/bloc/lock_screen_tap_bloc.dart';
import 'package:meu_tempo/features/overrun_alert/presentation/bloc/overrun_alert_bloc.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:meu_tempo/features/task/presentation/bloc/active_timer_bloc.dart';
import 'package:meu_tempo/features/task/presentation/bloc/edit_task_by_id_bloc.dart';
import 'package:meu_tempo/features/task/presentation/bloc/task_list_bloc.dart';
import 'package:meu_tempo/features/task/presentation/pages/edit_task_by_id_page.dart';
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

class _MockEditByIdBloc extends MockBloc<EditTaskByIdEvent, EditTaskByIdState>
    implements EditTaskByIdBloc {}

void main() {
  late _MockAuthBloc authBloc;
  late _MockActiveTimerBloc timerBloc;
  late _MockPermissionBloc permissionBloc;
  late _MockTapBloc tapBloc;
  late _MockOverrunAlertBloc overrunBloc;
  late AppRouter appRouter;

  setUpAll(() {
    registerFallbackValue(const ActiveTimerStarted());
    registerFallbackValue(const LockScreenPermissionStarted());
    registerFallbackValue(const LockScreenTapStarted());
  });

  setUp(() {
    authBloc = _MockAuthBloc();
    timerBloc = _MockActiveTimerBloc();
    permissionBloc = _MockPermissionBloc();
    tapBloc = _MockTapBloc();
    overrunBloc = _MockOverrunAlertBloc();
    when(() => overrunBloc.state).thenReturn(const OverrunAlertHidden());
    final taskListBloc = _MockTaskListBloc();
    final agendaBloc = _MockAgendaBloc();
    final editByIdBloc = _MockEditByIdBloc();

    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthAuthenticated(
        UserEntity(uid: 'u1', email: 'a@b.com'),
      ),
    );
    when(() => timerBloc.state).thenReturn(const ActiveTimerHidden());
    when(
      () => permissionBloc.state,
    ).thenReturn(const LockScreenPermissionBannerHidden());
    when(() => tapBloc.state).thenReturn(const LockScreenTapIdle());
    when(() => taskListBloc.state).thenReturn(const TaskListLoading());
    when(() => agendaBloc.state).thenReturn(const AgendaLoading());
    when(() => editByIdBloc.state).thenReturn(const EditTaskByIdLoading());

    getIt
      ..registerFactory<TaskListBloc>(() => taskListBloc)
      ..registerFactory<AgendaBloc>(() => agendaBloc)
      ..registerFactory<EditTaskByIdBloc>(() => editByIdBloc);
    appRouter = AppRouter(authBloc);
  });

  tearDown(() async => getIt.reset());

  Future<void> open(WidgetTester tester, String location) async {
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

  testWidgets('task opens the edit by id', (tester) async {
    await open(
      tester,
      Routes.timerTargetLocation(TimerTargetTypeEnum.task, 't1'),
    );

    expect(
      tester.widget<EditTaskByIdPage>(find.byType(EditTaskByIdPage)).taskId,
      't1',
    );
  });

  testWidgets('appointment opens the agenda', (tester) async {
    await open(
      tester,
      Routes.timerTargetLocation(TimerTargetTypeEnum.appointment, 'a1'),
    );

    expect(find.byType(AgendaPage), findsOneWidget);
  });

  testWidgets('unknown type goes back to the task list', (tester) async {
    await open(tester, '${Routes.timerTarget}?type=x&id=t1');

    expect(find.byType(TaskListPage), findsOneWidget);
  });

  testWidgets('missing id goes back to the task list', (tester) async {
    await open(tester, '${Routes.timerTarget}?type=task');

    expect(find.byType(TaskListPage), findsOneWidget);
  });

  testWidgets('the shell wires the banner', (tester) async {
    await open(tester, Routes.home);

    verify(
      () => permissionBloc.add(const LockScreenPermissionStarted()),
    ).called(1);
  });
}
