import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary colors
  static const Color primaryColor = Color(0xFF1976D2); // Medical blue
  static const Color primaryLightColor = Color(0xFF42A5F5);
  static const Color primaryDarkColor = Color(0xFF0D47A1);
  
  // Secondary colors
  static const Color secondaryColor = Color(0xFF26A69A); // Teal
  static const Color secondaryLightColor = Color(0xFF4DB6AC);
  static const Color secondaryDarkColor = Color(0xFF00796B);
  
  // Neutral colors
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);
  static const Color warningColor = Color(0xFFFFA000);
  
  // Text colors
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color textDisabledColor = Color(0xFFBDBDBD);
  
  // Dark theme colors
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkTextPrimaryColor = Color(0xFFEEEEEE);
  static const Color darkTextSecondaryColor = Color(0xFFB0B0B0);
  
  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: primaryLightColor,
      onPrimaryContainer: Colors.white,
      secondary: secondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: secondaryLightColor,
      onSecondaryContainer: Colors.white,
      error: errorColor,
      onError: Colors.white,
      surface: surfaceColor,
      onSurface: textPrimaryColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.notoSansArabic(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.notoSansArabic(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      displayMedium: GoogleFonts.notoSansArabic(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      displaySmall: GoogleFonts.notoSansArabic(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      headlineMedium: GoogleFonts.notoSansArabic(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      headlineSmall: GoogleFonts.notoSansArabic(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      titleLarge: GoogleFonts.notoSansArabic(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      bodyLarge: GoogleFonts.notoSansArabic(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textPrimaryColor,
      ),
      bodyMedium: GoogleFonts.notoSansArabic(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textPrimaryColor,
      ),
      bodySmall: GoogleFonts.notoSansArabic(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textSecondaryColor,
      ),
    ),
    cardTheme: CardTheme(
      color: surfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.notoSansArabic(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.notoSansArabic(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: GoogleFonts.notoSansArabic(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: textDisabledColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: textDisabledColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      labelStyle: GoogleFonts.notoSansArabic(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textSecondaryColor,
      ),
      hintStyle: GoogleFonts.notoSansArabic(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textDisabledColor,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaceColor,
      indicatorColor: primaryLightColor.withValues(alpha: 77),
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.notoSansArabic(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: primaryLightColor,
      onPrimary: Colors.black,
      primaryContainer: primaryDarkColor,
      onPrimaryContainer: Colors.white,
      secondary: secondaryLightColor,
      onSecondary: Colors.black,
      secondaryContainer: secondaryDarkColor,
      onSecondaryContainer: Colors.white,
      error: errorColor,
      onError: Colors.white,
      surface: darkSurfaceColor,
      onSurface: darkTextPrimaryColor,
    ),
    scaffoldBackgroundColor: darkBackgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: darkSurfaceColor,
      foregroundColor: darkTextPrimaryColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.notoSansArabic(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: darkTextPrimaryColor,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.notoSansArabic(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: darkTextPrimaryColor,
      ),
      displayMedium: GoogleFonts.notoSansArabic(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: darkTextPrimaryColor,
      ),
      displaySmall: GoogleFonts.notoSansArabic(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: darkTextPrimaryColor,
      ),
      headlineMedium: GoogleFonts.notoSansArabic(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: darkTextPrimaryColor,
      ),
      headlineSmall: GoogleFonts.notoSansArabic(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: darkTextPrimaryColor,
      ),
      titleLarge: GoogleFonts.notoSansArabic(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: darkTextPrimaryColor,
      ),
      bodyLarge: GoogleFonts.notoSansArabic(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: darkTextPrimaryColor,
      ),
      bodyMedium: GoogleFonts.notoSansArabic(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: darkTextPrimaryColor,
      ),
      bodySmall: GoogleFonts.notoSansArabic(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: darkTextSecondaryColor,
      ),
    ),
    cardTheme: CardTheme(
      color: darkSurfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryLightColor,
        foregroundColor: Colors.black,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.notoSansArabic(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryLightColor,
        side: const BorderSide(color: primaryLightColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.notoSansArabic(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryLightColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: GoogleFonts.notoSansArabic(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurfaceColor.withValues(alpha: 204),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkTextSecondaryColor.withValues(alpha: 128), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkTextSecondaryColor.withValues(alpha: 128), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryLightColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      labelStyle: GoogleFonts.notoSansArabic(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: darkTextSecondaryColor,
      ),
      hintStyle: GoogleFonts.notoSansArabic(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: darkTextSecondaryColor.withValues(alpha: 179),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkSurfaceColor,
      indicatorColor: primaryLightColor.withValues(alpha: 77),
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.notoSansArabic(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}