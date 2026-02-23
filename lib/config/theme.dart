import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBrown = Color(0xFF5D4037);
  static const Color darkBrown = Color(0xFF3E2723);
  static const Color accentOrange = Color(0xFFFF6F00);
  static const Color lightCream = Color(0xFFFFFBF0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // ✅ Safe Material 3 color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBrown,
      ),

      // ✅ CRITICAL FIX (ALLOW BACKGROUND IMAGE)
      scaffoldBackgroundColor: Colors.transparent,

      // ✅ AppBar made transparent-friendly
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // ✅ FIX
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBrown,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Text fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white, // cards stay readable
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: primaryBrown,
            width: 2,
          ),
        ),
      ),

      // Typography
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkBrown,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: darkBrown,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: darkBrown,
        ),
      ),
    );
  }
}
