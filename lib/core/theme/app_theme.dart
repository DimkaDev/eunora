import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF67594E); // Warm Taupe
  static const Color primaryContainer = Color(0xFF817266);
  static const Color surface = Color(0xFFFEF8F6); // Base surface
  static const Color surfaceContainerLow = Color(0xFFF8F2F0);
  static const Color surfaceContainer = Color(0xFFF2EDEA);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerHighest = Color(0xFFE7E1DF);
  static const Color onSurface = Color(0xFF1D1B1A);
  static const Color onSurfaceVariant = Color(0xFF4D453F);
  static const Color background = Color(0xFFFEF8F6);
  static const Color outline = Color(0xFF7F756E);
  static const Color outlineVariant = Color(0xFFD0C4BC);
  static const Color error = Color(0xFFBA1A1A);
  static const Color primaryFixed = Color(0xFFF2DFD0);
  static const Color tertiaryFixed = Color(0xFFFFDAD3); // Peachy Rose

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        primaryContainer: primaryContainer,
        surface: surface,
        onSurface: onSurface,
        tertiary: tertiaryFixed,
      ),
      scaffoldBackgroundColor: surface,
      useMaterial3: true,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.notoSerif(color: onSurface, fontSize: 56, fontWeight: FontWeight.normal),
        headlineMedium: GoogleFonts.notoSerif(color: onSurface, fontSize: 28, fontWeight: FontWeight.normal),
        titleLarge: GoogleFonts.manrope(color: onSurface, fontSize: 22, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.manrope(color: onSurface, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.manrope(color: onSurface, fontSize: 16),
        bodyMedium: GoogleFonts.manrope(color: onSurface, fontSize: 14),
        labelMedium: GoogleFonts.manrope(color: onSurface, fontSize: 12),
        labelSmall: GoogleFonts.manrope(color: onSurface, fontSize: 11),
      ),
    );
  }
}
