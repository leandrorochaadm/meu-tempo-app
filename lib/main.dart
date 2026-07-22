import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'firebase_options.dart';

Future<void> main() async {
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
