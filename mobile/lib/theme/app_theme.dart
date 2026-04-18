import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colours
  static const Color primary = Color(0xFF534AB7);
  static const Color teal = Color(0xFF0F6E56);
  static const Color amber = Color(0xFF854F0B);
  static const Color danger = Color(0xFFA32D2D);
  static const Color surface = Color(0xFF13111F);
  static const Color surfaceCard = Color(0xFF1E1B30);
  static const Color surfaceElevated = Color(0xFF272340);
  static const Color onSurface = Color(0xFFF2F0FF);
  static const Color onSurfaceMuted = Color(0xFF9590B8);
  static const Color eligible = Color(0xFF22C55E);
  static const Color suspended = Color(0xFFFBBF24);
  static const Color expired = Color(0xFFEF4444);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surface,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: teal,
        error: danger,
        surface: surfaceCard,
        onPrimary: Colors.white,
        onSurface: onSurface,
      ),
      textTheme: TextTheme(
        displayLarge: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 32, color: onSurface),
        displayMedium: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 24, color: onSurface),
        titleLarge: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 20, color: onSurface),
        titleMedium: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16, color: onSurface),
        bodyLarge: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 16, color: onSurface),
        bodyMedium: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 14, color: onSurfaceMuted),
        labelLarge: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
      ),
      cardTheme: CardTheme(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 18, color: onSurface),
        iconTheme: IconThemeData(color: onSurface),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceCard,
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3A3560), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 2)),
        labelStyle: const TextStyle(color: onSurfaceMuted, fontFamily: 'Inter'),
        hintStyle: const TextStyle(color: onSurfaceMuted, fontFamily: 'Inter'),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: surfaceElevated,
        labelStyle: TextStyle(fontFamily: 'Inter', fontSize: 12),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      dividerColor: Color(0xFF2A2745),
    );
  }
}
