import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/task/presentation/bloc/task_list_bloc.dart';
import '../../features/task/presentation/pages/task_list_page.dart';
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
      GoRoute(
        path: Routes.home,
        builder: (_, _) => BlocProvider(
          create: (_) => getIt<TaskListBloc>(),
          child: const TaskListPage(),
        ),
      ),
    ],
  );
}
