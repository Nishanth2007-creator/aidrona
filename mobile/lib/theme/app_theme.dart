import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colours
  static const Color primary = Color(0xFF6C5CE7);
  static const Color teal = Color(0xFF00B894);
  static const Color amber = Color(0xFFFDAC42);
  static const Color danger = Color(0xFFE74C3C);
  static const Color surface = Color(0xFF0D0B1A);
  static const Color surfaceCard = Color(0xFF161428);
  static const Color surfaceElevated = Color(0xFF1E1A36);
  static const Color onSurface = Color(0xFFF4F2FF);
  static const Color onSurfaceMuted = Color(0xFF8A84B0);
  static const Color eligible = Color(0xFF22C55E);
  static const Color suspended = Color(0xFFFBBF24);
  static const Color expired = Color(0xFFEF4444);

  static ThemeData get darkTheme {
    final base = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
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
      textTheme: base.copyWith(
        displayLarge: base.displayLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 32, color: onSurface),
        displayMedium: base.displayMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 24, color: onSurface),
        titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 20, color: onSurface),
        titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 16, color: onSurface),
        bodyLarge: base.bodyLarge?.copyWith(fontWeight: FontWeight.w400, fontSize: 16, color: onSurface),
        bodyMedium: base.bodyMedium?.copyWith(fontWeight: FontWeight.w400, fontSize: 14, color: onSurfaceMuted),
        labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
      ),
      cardTheme: const CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 18, color: onSurface),
        iconTheme: IconThemeData(color: onSurface),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF12101F),
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 11),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2A2548), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primary, width: 2)),
        labelStyle: const TextStyle(color: onSurfaceMuted, fontFamily: 'Inter'),
        hintStyle: const TextStyle(color: onSurfaceMuted, fontFamily: 'Inter'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: surfaceElevated,
        labelStyle: TextStyle(fontFamily: 'Inter', fontSize: 12),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      dividerColor: const Color(0xFF221F3A),
    );
  }
}
