import 'package:flutter/material.dart';

/// A utility class that provides Tailwind CSS-like utility classes for Flutter
/// This allows for more consistent styling across the app
class TailwindUtils {
  // Colors
  static const Color primary = Color(0xFF1976D2);
  static const Color secondary = Color(0xFF26A69A);
  static const Color success = Color(0xFF388E3C);
  static const Color danger = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(0xFF42A5F5);
  static const Color light = Color(0xFFF5F5F5);
  static const Color dark = Color(0xFF212121);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = Color(0xFF212121);
  
  // Spacing
  static const double spacing0 = 0.0;
  static const double spacing1 = 4.0;
  static const double spacing2 = 8.0;
  static const double spacing3 = 12.0;
  static const double spacing4 = 16.0;
  static const double spacing5 = 20.0;
  static const double spacing6 = 24.0;
  static const double spacing8 = 32.0;
  static const double spacing10 = 40.0;
  static const double spacing12 = 48.0;
  static const double spacing16 = 64.0;
  static const double spacing20 = 80.0;
  static const double spacing24 = 96.0;
  
  // Font sizes
  static const double textXs = 12.0;
  static const double textSm = 14.0;
  static const double textBase = 16.0;
  static const double textLg = 18.0;
  static const double textXl = 20.0;
  static const double text2xl = 24.0;
  static const double text3xl = 30.0;
  static const double text4xl = 36.0;
  static const double text5xl = 48.0;
  
  // Font weights
  static const FontWeight fontThin = FontWeight.w100;
  static const FontWeight fontExtraLight = FontWeight.w200;
  static const FontWeight fontLight = FontWeight.w300;
  static const FontWeight fontNormal = FontWeight.w400;
  static const FontWeight fontMedium = FontWeight.w500;
  static const FontWeight fontSemiBold = FontWeight.w600;
  static const FontWeight fontBold = FontWeight.w700;
  static const FontWeight fontExtraBold = FontWeight.w800;
  static const FontWeight fontBlack = FontWeight.w900;
  
  // Border radius
  static const double roundedNone = 0.0;
  static const double roundedSm = 2.0;
  static const double rounded = 4.0;
  static const double roundedMd = 6.0;
  static const double roundedLg = 8.0;
  static const double roundedXl = 12.0;
  static const double rounded2xl = 16.0;
  static const double rounded3xl = 24.0;
  static const double roundedFull = 9999.0;
  
  // Shadows
  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Colors.black.withAlpha(13), // 0.05 * 255 = ~13
      blurRadius: 1.0,
      offset: const Offset(0, 1),
    ),
  ];
  
  static List<BoxShadow> shadow = [
    BoxShadow(
      color: Colors.black.withAlpha(26), // 0.1 * 255 = ~26
      blurRadius: 3.0,
      offset: const Offset(0, 1),
    ),
  ];
  
  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Colors.black.withAlpha(26), // 0.1 * 255 = ~26
      blurRadius: 6.0,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Colors.black.withAlpha(26), // 0.1 * 255 = ~26
      blurRadius: 10.0,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Colors.black.withAlpha(26), // 0.1 * 255 = ~26
      blurRadius: 20.0,
      offset: const Offset(0, 12),
    ),
  ];
  
  // Utility methods for padding
  static EdgeInsets p0 = const EdgeInsets.all(spacing0);
  static EdgeInsets p1 = const EdgeInsets.all(spacing1);
  static EdgeInsets p2 = const EdgeInsets.all(spacing2);
  static EdgeInsets p3 = const EdgeInsets.all(spacing3);
  static EdgeInsets p4 = const EdgeInsets.all(spacing4);
  static EdgeInsets p5 = const EdgeInsets.all(spacing5);
  static EdgeInsets p6 = const EdgeInsets.all(spacing6);
  static EdgeInsets p8 = const EdgeInsets.all(spacing8);
  
  // Horizontal padding
  static EdgeInsets px0 = const EdgeInsets.symmetric(horizontal: spacing0);
  static EdgeInsets px1 = const EdgeInsets.symmetric(horizontal: spacing1);
  static EdgeInsets px2 = const EdgeInsets.symmetric(horizontal: spacing2);
  static EdgeInsets px3 = const EdgeInsets.symmetric(horizontal: spacing3);
  static EdgeInsets px4 = const EdgeInsets.symmetric(horizontal: spacing4);
  static EdgeInsets px5 = const EdgeInsets.symmetric(horizontal: spacing5);
  static EdgeInsets px6 = const EdgeInsets.symmetric(horizontal: spacing6);
  static EdgeInsets px8 = const EdgeInsets.symmetric(horizontal: spacing8);
  
  // Vertical padding
  static EdgeInsets py0 = const EdgeInsets.symmetric(vertical: spacing0);
  static EdgeInsets py1 = const EdgeInsets.symmetric(vertical: spacing1);
  static EdgeInsets py2 = const EdgeInsets.symmetric(vertical: spacing2);
  static EdgeInsets py3 = const EdgeInsets.symmetric(vertical: spacing3);
  static EdgeInsets py4 = const EdgeInsets.symmetric(vertical: spacing4);
  static EdgeInsets py5 = const EdgeInsets.symmetric(vertical: spacing5);
  static EdgeInsets py6 = const EdgeInsets.symmetric(vertical: spacing6);
  static EdgeInsets py8 = const EdgeInsets.symmetric(vertical: spacing8);
  
  // Utility methods for margin
  static EdgeInsets m0 = const EdgeInsets.all(spacing0);
  static EdgeInsets m1 = const EdgeInsets.all(spacing1);
  static EdgeInsets m2 = const EdgeInsets.all(spacing2);
  static EdgeInsets m3 = const EdgeInsets.all(spacing3);
  static EdgeInsets m4 = const EdgeInsets.all(spacing4);
  static EdgeInsets m5 = const EdgeInsets.all(spacing5);
  static EdgeInsets m6 = const EdgeInsets.all(spacing6);
  static EdgeInsets m8 = const EdgeInsets.all(spacing8);
  
  // Horizontal margin
  static EdgeInsets mx0 = const EdgeInsets.symmetric(horizontal: spacing0);
  static EdgeInsets mx1 = const EdgeInsets.symmetric(horizontal: spacing1);
  static EdgeInsets mx2 = const EdgeInsets.symmetric(horizontal: spacing2);
  static EdgeInsets mx3 = const EdgeInsets.symmetric(horizontal: spacing3);
  static EdgeInsets mx4 = const EdgeInsets.symmetric(horizontal: spacing4);
  static EdgeInsets mx5 = const EdgeInsets.symmetric(horizontal: spacing5);
  static EdgeInsets mx6 = const EdgeInsets.symmetric(horizontal: spacing6);
  static EdgeInsets mx8 = const EdgeInsets.symmetric(horizontal: spacing8);
  
  // Vertical margin
  static EdgeInsets my0 = const EdgeInsets.symmetric(vertical: spacing0);
  static EdgeInsets my1 = const EdgeInsets.symmetric(vertical: spacing1);
  static EdgeInsets my2 = const EdgeInsets.symmetric(vertical: spacing2);
  static EdgeInsets my3 = const EdgeInsets.symmetric(vertical: spacing3);
  static EdgeInsets my4 = const EdgeInsets.symmetric(vertical: spacing4);
  static EdgeInsets my5 = const EdgeInsets.symmetric(vertical: spacing5);
  static EdgeInsets my6 = const EdgeInsets.symmetric(vertical: spacing6);
  static EdgeInsets my8 = const EdgeInsets.symmetric(vertical: spacing8);
}