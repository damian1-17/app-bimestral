import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primary      = Color(0xFF1B3A6B);
  static const Color primaryLight = Color(0xFF2E5FA3);
  static const Color accent       = Color(0xFF0D9488);
  static const Color background   = Color(0xFFF8F9FB);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color textDark     = Color(0xFF111827);
  static const Color textMedium   = Color(0xFF6B7280);
  static const Color textLight    = Color(0xFF9CA3AF);
  static const Color border       = Color(0xFFE5E7EB);
  static const Color errorColor   = Color(0xFFDC2626);
  static const Color success      = Color(0xFF16A34A);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.light(
      primary:   primary,
      secondary: accent,
      surface:   surface,
      error:     errorColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        elevation: 2,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: errorColor),
      ),
      labelStyle: const TextStyle(color: textMedium, fontSize: 14),
      hintStyle: const TextStyle(color: textLight, fontSize: 14),
    ),
  );
}