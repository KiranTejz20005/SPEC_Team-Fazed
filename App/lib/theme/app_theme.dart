import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color primaryGreen = Color(0xFF2ECC71);
  static const Color primaryPurple = Color(0xFF9B59B6);
  static const Color primaryOrange = Color(0xFFE67E22);
  static const Color primaryPink = Color(0xFFE91E63);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6C757D);
  static const Color lightBorder = Color(0xFFE0E0E0);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkBorder = Color(0xFF333333);
  static const Color darkAccent = Color(0xFFE0E0E0);

  ThemeData getTheme(String themeName) {
    Color primaryColor;
    Color accentColor;

    switch (themeName) {
      case 'green':
        primaryColor = primaryGreen;
        accentColor = primaryGreen;
        break;
      case 'purple':
        primaryColor = primaryPurple;
        accentColor = primaryPurple;
        break;
      case 'orange':
        primaryColor = primaryOrange;
        accentColor = primaryOrange;
        break;
      case 'pink':
        primaryColor = primaryPink;
        accentColor = primaryPink;
        break;
      case 'dark':
        primaryColor = darkAccent;
        accentColor = darkAccent;
        break;
      default: // light
        primaryColor = primaryBlue;
        accentColor = primaryBlue;
    }

    final isDark = themeName == 'dark';

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primaryColor,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: accentColor,
        onSecondary: Colors.white,
        error: const Color(0xFFE74C3C),
        onError: Colors.white,
        surface: isDark ? darkSurface : lightSurface,
        onSurface: isDark ? darkTextPrimary : lightTextPrimary,
      ),
      scaffoldBackgroundColor: isDark ? darkBackground : lightBackground,
      cardColor: isDark ? darkSurface : lightSurface,
      dividerColor: isDark ? darkBorder : lightBorder,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? darkTextPrimary : lightTextPrimary,
        ),
        titleTextStyle: TextStyle(
          color: isDark ? darkTextPrimary : lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? darkSurface : lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: isDark ? darkTextPrimary : lightTextPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: isDark ? darkTextPrimary : lightTextPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: isDark ? darkTextPrimary : lightTextPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: isDark ? darkTextPrimary : lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: isDark ? darkTextPrimary : lightTextPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: isDark ? darkTextSecondary : lightTextSecondary,
          fontSize: 14,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkSurface : lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? darkBorder : lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? darkBorder : lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }
}

