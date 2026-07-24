import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/appointment/presentation/bloc/agenda_bloc.dart';
import '../../features/appointment/presentation/pages/agenda_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/config/presentation/bloc/settings_bloc.dart';
import '../../features/config/presentation/pages/settings_page.dart';
import '../../features/list/presentation/bloc/list_manager_bloc.dart';
import '../../features/list/presentation/pages/lists_page.dart';
import '../../features/report/domain/entities/report_period_enum.dart';
import '../../features/report/presentation/bloc/report_bloc.dart';
import '../../features/report/presentation/bloc/report_detail_bloc.dart';
import '../../features/report/presentation/pages/report_detail_page.dart';
import '../../features/report/presentation/pages/report_page.dart';
import '../../features/task/domain/entities/task_entity.dart';
import '../../features/task/presentation/bloc/task_list_bloc.dart';
import '../../features/task/presentation/bloc/time_entry_bloc.dart';
import '../../features/task/presentation/pages/edit_task_args.dart';
import '../../features/task/presentation/pages/edit_task_page.dart';
import '../../features/task/presentation/pages/task_list_page.dart';
import '../../features/task/presentation/pages/time_entry_page.dart';
import '../../features/task/presentation/widgets/active_timer_bar.dart';
import '../di/injection.dart';
import 'go_router_refresh_stream.dart';
import 'routes.dart';

/// Raiz de composição do roteamento. Reage ao estado de auth via
/// `refreshListenable` e redireciona login/home conforme a sessão.
class AppRouter {
  AppRouter(this._authBloc);

  final AuthBloc _authBloc;

  late final GoRouter router = GoRouter(
    initialLocation: Routes.home,
    refreshListenable: GoRouterRefreshStream(_authBloc.stream),
    redirect: (context, state) {
      final authState = _authBloc.state;
      final loggedIn = authState is AuthAuthenticated;
      final loggingIn = state.matchedLocation == Routes.login;

      // Enquanto resolve o estado inicial, não redireciona.
      if (authState is AuthInitial || authState is AuthLoading) return null;

      if (!loggedIn) return loggingIn ? null : Routes.login;
      if (loggingIn) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (_, _) => const LoginPage(),
      ),
      // Shell das rotas autenticadas: mantém a barra "now playing" fixa no
      // rodapé, dentro do Navigator raiz (assim seus Tooltip/diálogos têm
      // Overlay/Navigator). O login fica fora — sem barra.
      ShellRoute(
        builder: (_, _, child) => AppShell(child: child),
        routes: [
      GoRoute(
        path: Routes.home,
        builder: (_, _) => BlocProvider(
          create: (_) => getIt<TaskListBloc>(),
          child: const TaskListPage(),
        ),
      ),
      GoRoute(
        path: Routes.lists,
        builder: (_, _) => BlocProvider(
          create: (_) => getIt<ListManagerBloc>(),
          child: const ListsPage(),
        ),
      ),
      GoRoute(
        path: Routes.agenda,
        builder: (_, _) => BlocProvider(
          create: (_) => getIt<AgendaBloc>(),
          child: const AgendaPage(),
        ),
      ),
      GoRoute(
        path: Routes.report,
        builder: (_, _) => BlocProvider(
          create: (_) => getIt<ReportBloc>(),
          child: const ReportPage(),
        ),
      ),
      GoRoute(
        path: Routes.reportDetail,
        builder: (_, state) {
          final q = state.uri.queryParameters;
          return BlocProvider(
            create: (_) => getIt<ReportDetailBloc>(),
            child: ReportDetailPage(
              listId: q['list'] ?? '',
              period: ReportPeriodEnum.values.byName(q['period'] ?? 'day'),
              offset: int.tryParse(q['offset'] ?? '0') ?? 0,
              listName: state.extra as String?,
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.settings,
        builder: (_, _) => BlocProvider(
          create: (_) => getIt<SettingsBloc>(),
          child: const SettingsPage(),
        ),
      ),
      GoRoute(
        path: Routes.editTask,
        builder: (context, state) {
          // `extra` não sobrevive a refresh do PWA — volta pra home nesse caso.
          final args = state.extra;
          if (args is! EditTaskArgs) {
            return BlocProvider(
              create: (_) => getIt<TaskListBloc>(),
              child: const TaskListPage(),
            );
          }
          return EditTaskPage(args: args, today: DateTime.now());
        },
      ),
      GoRoute(
        path: Routes.timeEntry,
        builder: (context, state) {
          final leaf = state.extra;
          if (leaf is! TaskEntity) {
            return BlocProvider(
              create: (_) => getIt<TaskListBloc>(),
              child: const TaskListPage(),
            );
          }
          return BlocProvider(
            create: (_) => getIt<TimeEntryBloc>(),
            child: TimeEntryPage(leaf: leaf),
          );
        },
      ),
        ],
      ),
    ],
  );
}

/// Casca das telas autenticadas: empilha a barra do cronômetro no rodapé, acima
/// da área segura, com o conteúdo da rota preenchendo o restante.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: child),
        const ActiveTimerBar(),
      ],
    );
  }
}
