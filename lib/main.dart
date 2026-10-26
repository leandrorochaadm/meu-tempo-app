import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/bootstrap/app_services_bootstrap.dart';
import 'core/config/app_config.dart';
import 'core/di/injection.dart';
import 'core/logging/app_logger.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/ui/app_error_screen.dart';
import 'core/ui/app_not_configured_screen.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/lock_screen/data/background/lock_screen_action_entrypoint.dart';
import 'features/lock_screen/presentation/bloc/lock_screen_permission_bloc.dart';
import 'features/lock_screen/presentation/bloc/lock_screen_sync_bloc.dart';
import 'features/lock_screen/presentation/bloc/lock_screen_tap_bloc.dart';
import 'features/lock_screen/presentation/widgets/lock_screen_sync_listener.dart';
import 'features/overrun_alert/presentation/bloc/overrun_alert_bloc.dart';
import 'features/task/presentation/bloc/active_timer_bloc.dart';

Future<void> main() async {
  // Rede de segurança: qualquer exceção não capturada (inclusive assíncrona,
  // como erro de stream do tempo real ou da sessão) é logada em vez de morrer em silêncio
  // deixando a tela branca. Em release o `dart2js` remove as mensagens de erro,
  // então logar aqui é a única forma de ver a causa real.
  FlutterError.onError = (details) {
    AppLogger.logError(
      'FlutterError não capturado',
      error: details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };

  // Erro no `build` de um widget: em release o Flutter mostraria uma tela cinza
  // sem contexto. Troca por uma tela de erro no tema do app com botão recarregar.
  ErrorWidget.builder = (details) => const AppErrorScreen();

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Build without config: show the notice and skip services (DI, PocketBase).
      final missingKeys = AppConfig.missingKeys;
      if (missingKeys.isNotEmpty) {
        AppLogger.logError('App config missing: ${missingKeys.join(', ')}');
        runApp(const AppNotConfiguredApp());
        return;
      }

      await initializeAppServices();
      await initializeDateFormatting('pt_BR');

      runApp(const MeuTempoApp());
    },
    (error, stack) {
      AppLogger.logError(
        'Erro não capturado no boot',
        error: error,
        stackTrace: stack,
      );
    },
  );
}

/// Background entrypoint of the lock screen actions (pause, resume, confirmed
/// stop). The NAME is a contract with `android/` and `ios/` (`DartEntrypoint` /
/// `run(withEntrypoint:)`): do not rename without changing there.
@pragma('vm:entry-point')
Future<void> lockScreenActionMain() => runLockScreenActionEntrypoint();

class MeuTempoApp extends StatelessWidget {
  const MeuTempoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => getIt<AuthBloc>()),
        // Estado global do cronômetro ativo — a barra "now playing" abaixo do
        // router o consome em qualquer tela.
        BlocProvider<ActiveTimerBloc>(create: (_) => getIt<ActiveTimerBloc>()),
        // Mirrors the active timer on the lock screen / notification shade
        // (empty implementation on web).
        BlocProvider<LockScreenSyncBloc>(
          create: (_) => getIt<LockScreenSyncBloc>(),
        ),
        // "Ative os avisos..." banner — switched on/off by the AppShell.
        BlocProvider<LockScreenPermissionBloc>(
          create: (_) => getIt<LockScreenPermissionBloc>(),
        ),
        // Taps on the lock screen timer: subscribes right at app start (not
        // lazy) so the tap that opened the app is not lost.
        BlocProvider<LockScreenTapBloc>(
          lazy: false,
          create: (_) =>
              getIt<LockScreenTapBloc>()..add(const LockScreenTapStarted()),
        ),
        // Overrun alert — switched on/off by the AppShell.
        BlocProvider<OverrunAlertBloc>(
          create: (_) => getIt<OverrunAlertBloc>(),
        ),
      ],
      child: LockScreenSyncListener(
        child: Builder(
          builder: (context) {
            final router = AppRouter(context.read<AuthBloc>()).router;
            return MaterialApp.router(
              title: 'Meu Tempo',
              debugShowCheckedModeBanner: false,
              themeMode: ThemeMode.dark,
              theme: AppTheme.dark,
              darkTheme: AppTheme.dark,
              routerConfig: router,
            );
          },
        ),
      ),
    );
  }
}
