import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/di/injection.dart';
import 'core/logging/app_logger.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/ui/app_error_screen.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Rede de segurança: qualquer exceção não capturada (inclusive assíncrona,
  // como erro de stream do Firestore/Auth) é logada em vez de morrer em silêncio
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

  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // App sempre online — sem cache offline (ver design/fricção zero).
    FirebaseFirestore.instance.settings =
        const Settings(persistenceEnabled: false);

    await initializeDateFormatting('pt_BR');
    await configureDependencies();

    runApp(const MeuTempoApp());
  }, (error, stack) {
    AppLogger.logError(
      'Erro não capturado no boot',
      error: error,
      stackTrace: stack,
    );
  });
}

class MeuTempoApp extends StatelessWidget {
  const MeuTempoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => getIt<AuthBloc>(),
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
    );
  }
}
