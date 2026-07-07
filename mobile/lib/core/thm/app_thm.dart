import 'package:flutter/material.dart';

class AppThm {
  AppThm._();

  static const Color priClr = Color(0xFF1D3F73); // Azul SEGURA EP
  static const Color secClr = Color(0xFF00A6D6); // Celeste institucional
  static const Color accClr = Color(0xFFFFC400); // Amarillo
  static const Color navClr = Color(0xFF2D2A5F); // Azul morado
  static const Color bgClr = Color(0xFFF4F8FB);
  static const Color txtClr = Color(0xFF1F2937);
  static const Color errClr = Color(0xFFD32F2F);
  static const Color okClr = Color(0xFF2E7D32);

  static ThemeData get lgt {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgClr,
      colorScheme: ColorScheme.fromSeed(
        seedColor: priClr,
        primary: priClr,
        secondary: secClr,
        tertiary: accClr,
        error: errClr,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: priClr,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: priClr,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}