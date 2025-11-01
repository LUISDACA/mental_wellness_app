import 'package:flutter/material.dart';

class AppTheme {
  // Paleta "Serenidad Atlántica" - Teal + Lavanda para bienestar mental
  static const _oceanTeal = Color(0xFF00897B); // Teal océano (principal)
  static const _softTeal = Color(0xFF80CBC4); // Teal suave
  static const _lavender = Color(0xFFB39DDB); // Lavanda serena
  static const _softLavender = Color(0xFFE1BEE7); // Lavanda suave
  static const _skyBlue = Color(0xFFF0F7F7); // Azul cielo muy claro
  static const _mintGreen = Color(0xFFA5D6A7); // Verde menta

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: _oceanTeal,
          onPrimary: Colors.white,
          primaryContainer: _softTeal,
          onPrimaryContainer: Color(0xFF003833),
          secondary: _lavender,
          onSecondary: Colors.white,
          secondaryContainer: _softLavender,
          onSecondaryContainer: Color(0xFF311B92),
          tertiary: _mintGreen,
          onTertiary: Colors.white,
          tertiaryContainer: Color(0xFFDCEDC8),
          surface: _skyBlue,
          onSurface: Color(0xFF263238),
          error: Color(0xFFE57373),
          onError: Colors.white,
          outline: Color(0xFFB0BEC5),
          outlineVariant: Color(0xFFE0F2F1),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 57, fontWeight: FontWeight.w600, letterSpacing: -0.5),
          displayMedium: TextStyle(
              fontSize: 45, fontWeight: FontWeight.w600, letterSpacing: 0),
          displaySmall: TextStyle(
              fontSize: 36, fontWeight: FontWeight.w600, letterSpacing: 0),
          headlineLarge: TextStyle(
              fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: 0),
          headlineMedium: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: 0),
          headlineSmall: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 0),
          titleLarge: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: 0),
          titleMedium: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15),
          titleSmall: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
          bodyLarge: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5),
          bodyMedium: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
          bodySmall: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFB0BEC5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFB0BEC5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _oceanTeal, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: _skyBlue,
        ),
        chipTheme: ChipThemeData(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          elevation: 2,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: _softTeal, // Más suave para dark mode
          onPrimary: Color(0xFF003833),
          primaryContainer: Color(0xFF00695C), // Teal oscuro
          onPrimaryContainer: _softTeal,
          secondary: _lavender,
          onSecondary: Color(0xFF311B92),
          secondaryContainer: Color(0xFF512DA8), // Lavanda oscuro
          onSecondaryContainer: _softLavender,
          tertiary: _mintGreen,
          onTertiary: Color(0xFF1B5E20), // Verde oscuro
          tertiaryContainer: Color(0xFF388E3C),
          surface: Color(0xFF1A1C1E), // Superficie oscura
          onSurface: Color(0xFFE3E2E6), // Texto claro
          surfaceContainerHighest: Color(0xFF2B2D30), // Cards y containers
          error: Color(0xFFEF5350),
          onError: Color(0xFF370B1E),
          outline: Color(0xFF8C9099),
          outlineVariant: Color(0xFF43474E),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 57, fontWeight: FontWeight.w600, letterSpacing: -0.5),
          displayMedium: TextStyle(
              fontSize: 45, fontWeight: FontWeight.w600, letterSpacing: 0),
          displaySmall: TextStyle(
              fontSize: 36, fontWeight: FontWeight.w600, letterSpacing: 0),
          headlineLarge: TextStyle(
              fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: 0),
          headlineMedium: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: 0),
          headlineSmall: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 0),
          titleLarge: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: 0),
          titleMedium: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15),
          titleSmall: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
          bodyLarge: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5),
          bodyMedium: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
          bodySmall: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF2B2D30),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2B2D30),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF43474E)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF43474E)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _softTeal, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Color(0xFF1A1C1E),
        ),
        chipTheme: ChipThemeData(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          elevation: 2,
        ),
      );
}
