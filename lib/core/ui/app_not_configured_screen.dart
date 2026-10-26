import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_empty_state.dart';

/// Root app shown when the build has no config (`AppConfig.missingKeys`).
/// Depends only on the theme: no DI, no backend.
class AppNotConfiguredApp extends StatelessWidget {
  const AppNotConfiguredApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu Tempo',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      home: const AppNotConfiguredScreen(),
    );
  }
}

class AppNotConfiguredScreen extends StatelessWidget {
  const AppNotConfiguredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: AppEmptyState(
          icon: Icons.settings_rounded,
          title: 'O app não foi configurado.',
          message: 'Fale com o suporte.',
        ),
      ),
    );
  }
}
