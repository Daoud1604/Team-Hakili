import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Couleurs
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color accentGreen = Color(0xFF16A34A);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningYellow = Color(0xFFFACC15);
  static const Color neutralDark = Color(0xFF111827);
  static const Color neutralText = Color(0xFF4B5563);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color screenBackground = Color(0xFFF3F4F6);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryBlue,
        secondary: accentGreen,
        error: dangerRed,
        surface: cardBackground,
        background: screenBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onSurface: neutralDark,
        onBackground: neutralDark,
      ),
      scaffoldBackgroundColor: screenBackground,
      textTheme: GoogleFonts.robotoTextTheme().copyWith(
        displayLarge: GoogleFonts.roboto(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: neutralDark,
        ),
        displayMedium: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: neutralDark,
        ),
        titleLarge: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: neutralDark,
        ),
        titleMedium: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: neutralDark,
        ),
        bodyLarge: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: neutralDark,
        ),
        bodyMedium: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: neutralText,
        ),
        bodySmall: GoogleFonts.roboto(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: neutralText,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(0),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cardBackground,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.08),
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: neutralDark,
        ),
        iconTheme: const IconThemeData(color: neutralDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: screenBackground,
        selectedColor: primaryBlue.withOpacity(0.1),
        labelStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryBlue,
        inactiveTrackColor: Colors.grey.shade300,
        thumbColor: primaryBlue,
        overlayColor: primaryBlue.withOpacity(0.2),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return accentGreen;
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return accentGreen.withOpacity(0.5);
          }
          return Colors.grey.shade300;
        }),
      ),
    );
  }

  // Ombres légères
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ];

  // Espacement de base
  static const double baseSpacing = 16.0;
}
