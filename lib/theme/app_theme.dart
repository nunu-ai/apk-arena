import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// OFFICIAL NUNU THEME from https://nunu.ai/brand
class NunuColors {
    // Background
    static const Color backgroundDefault = Color(0xFF0A0A1C);
    static const Color backgroundPaper = Color(0xFF16122F);

    // Primary
    static const Color primaryDarker = Color(0xFF55116D);
    static const Color primaryDark = Color(0xFF9A2EA4);
    static const Color primaryMain = Color(0xFFE55CD8);
    static const Color primaryLight = Color(0xFFF79EDE);
    static const Color primaryLighter = Color(0xFFFDDFEF);

    // Secondary
    static const Color secondaryDarker = Color(0xFF1F116D);
    static const Color secondaryDark = Color(0xFF472EA4);
    static const Color secondaryMain = Color(0xFF805CE5);
    static const Color secondaryLight = Color(0xFFBA9EF7);
    static const Color secondaryLighter = Color(0xFFEADFFD);

    // Error
    static const Color errorDarker = Color(0xFF7A0916);
    static const Color errorDark = Color(0xFFB71D18);
    static const Color errorMain = Color(0xFFFF5630);
    static const Color errorLight = Color(0xFFFFAC82);
    static const Color errorLighter = Color(0xFFFFE9D5);

    // Success
    static const Color successDarker = Color(0xFF065E49);
    static const Color successDark = Color(0xFF118D57);
    static const Color successMain = Color(0xFF22C55E);
    static const Color successLight = Color(0xFF77ED8B);
    static const Color successLighter = Color(0xFFD3FCD2);

    // Info
    static const Color infoDarker = Color(0xFF003768);
    static const Color infoDark = Color(0xFF006C9C);
    static const Color infoMain = Color(0xFF00B8D9);
    static const Color infoLight = Color(0xFF61F3F3);
    static const Color infoLighter = Color(0xFFCAFDF5);

    // Warning
    static const Color warningDarker = Color(0xFF7A4100);
    static const Color warningDark = Color(0xFFB76E00);
    static const Color warningMain = Color(0xFFFFAB00);
    static const Color warningLight = Color(0xFFFFD666);
    static const Color warningLighter = Color(0xFFFFF5CC);
    
    // Text
    static const Color textPrimary = Color(0xFFFFFFFF);
    static const Color textSecondary = Color(0xB3FFFFFF);
}

class AppTheme {
  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.jetBrainsMonoTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: ColorScheme.dark(
        primary: NunuColors.primaryMain,
        primaryContainer: NunuColors.primaryDark,
        secondary: NunuColors.secondaryMain,
        secondaryContainer: NunuColors.secondaryDark,
        error: NunuColors.errorMain,
        surface: NunuColors.backgroundPaper,
        background: NunuColors.backgroundDefault,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
      ),

      // Scaffold
      scaffoldBackgroundColor: NunuColors.backgroundDefault,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: NunuColors.backgroundPaper,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.jetBrainsMono(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: NunuColors.backgroundPaper,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Text Theme
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(color: Colors.white),
        displayMedium: textTheme.displayMedium?.copyWith(color: Colors.white),
        displaySmall: textTheme.displaySmall?.copyWith(color: Colors.white),
        headlineLarge: textTheme.headlineLarge?.copyWith(color: Colors.white),
        headlineMedium: textTheme.headlineMedium?.copyWith(color: Colors.white),
        headlineSmall: textTheme.headlineSmall?.copyWith(color: Colors.white),
        titleLarge: textTheme.titleLarge?.copyWith(color: Colors.white),
        titleMedium: textTheme.titleMedium?.copyWith(color: Colors.white),
        titleSmall: textTheme.titleSmall?.copyWith(color: Colors.white),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: Colors.white),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: Colors.white),
        bodySmall: textTheme.bodySmall?.copyWith(color: Colors.white),
        labelLarge: textTheme.labelLarge?.copyWith(color: Colors.white),
        labelMedium: textTheme.labelMedium?.copyWith(color: Colors.white),
        labelSmall: textTheme.labelSmall?.copyWith(color: Colors.white),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NunuColors.primaryMain,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.jetBrainsMono(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: NunuColors.primaryMain,
          textStyle: GoogleFonts.jetBrainsMono(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NunuColors.primaryMain,
          side: const BorderSide(color: NunuColors.primaryMain),
          textStyle: GoogleFonts.jetBrainsMono(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NunuColors.backgroundPaper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: NunuColors.primaryMain),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: NunuColors.primaryDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: NunuColors.primaryMain, width: 2),
        ),
        labelStyle: GoogleFonts.jetBrainsMono(color: NunuColors.primaryLight),
        hintStyle: GoogleFonts.jetBrainsMono(color: Colors.white54),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: NunuColors.backgroundPaper,
        selectedColor: NunuColors.primaryMain,
        labelStyle: GoogleFonts.jetBrainsMono(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: NunuColors.primaryDark.withOpacity(0.3),
        thickness: 1,
      ),
    );
  }
}