import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/theme.dart'; // ← IMPORTAR EL TEMA
import 'routes.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bienestar Emocional',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'), // español
        Locale('en'), // inglés (por si el SO está en inglés)
      ],

      // ⭐ AQUÍ ESTÁ EL CAMBIO IMPORTANTE ⭐
      theme: AppTheme.light, // Tema claro personalizado
    );
  }
}
