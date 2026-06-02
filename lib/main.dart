import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'presentation/settings/settings_screen.dart';
import 'presentation/tuner/tuner_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: IsaacTunaApp(),
    ),
  );
}

class IsaacTunaApp extends StatelessWidget {
  const IsaacTunaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IsaacTuna',
      debugShowCheckedModeBanner: false,
      // Tema oscuro fijo — no responde al tema del sistema (requisito 8.1)
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.dark,
      // Ruta inicial
      initialRoute: '/',
      routes: {
        '/': (context) => const TunerScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
