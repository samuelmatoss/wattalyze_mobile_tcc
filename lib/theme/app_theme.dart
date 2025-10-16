import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Cores principais
  static const Color primaryGreen = Color(0xFF27ae60);
  static const Color primaryDark = Color(0xFF2c3e50);
  static const Color primaryOrange = Color(0xFFf39c12);
  static const Color primaryRed = Color(0xFFe74c3c);

  // Tema principal com Google Fonts
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
      ),

      // USAR GOOGLE FONTS para resolver problemas de caracteres
      textTheme: GoogleFonts.robotoTextTheme().copyWith(
        displayLarge: GoogleFonts.roboto(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryDark,
        ),
        displayMedium: GoogleFonts.roboto(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: primaryDark,
        ),
        headlineLarge: GoogleFonts.roboto(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primaryDark,
        ),
        headlineMedium: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryDark,
        ),
        bodyLarge: GoogleFonts.roboto(
          fontSize: 16,
          color: Colors.grey[800],
        ),
        bodyMedium: GoogleFonts.roboto(
          fontSize: 14,
          color: Colors.grey[700],
        ),
        bodySmall: GoogleFonts.roboto(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 4,
        margin: EdgeInsets.all(8),
      ),
    );
  }

  // Estilos específicos
  static TextStyle get emojiStyle => GoogleFonts.roboto(
        fontSize: 16,
      );

  static TextStyle get monospaceStyle => GoogleFonts.robotoMono(
        fontSize: 14,
      );
}
