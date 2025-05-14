import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary colors
  static const Color primaryColor = Color.fromARGB(255, 159, 155, 230);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color accentColor = Color(0xFFFF4081);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkCard = Color(0xFF2C2C2C);
  static const Color darkDivider = Color(0xFF3E3E3E);
  static const Color darkOutline = Color(0xFF4A4A4A);

  // Text colors - Updated for better visibility
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // Changed to white
  static const Color darkTextSecondary =
      Color(0xFFE0E0E0); // Lighter secondary text
  static const Color darkTextHint = Color(0xFFB0B0B0); // Lighter hint text

  // Status colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFFA726);
  static const Color infoColor = Color(0xFF29B6F6);

  // Font families
  static final TextTheme _mainTextTheme = GoogleFonts.poppinsTextTheme().apply(
    bodyColor: darkTextPrimary,
    displayColor: darkTextPrimary,
  );
  static final TextTheme _journalTextTheme =
      GoogleFonts.poppinsTextTheme().apply(
    bodyColor: darkTextPrimary,
    displayColor: darkTextPrimary,
  );
  static final TextTheme _splashTextTheme =
      GoogleFonts.montserratTextTheme().apply(
    bodyColor: darkTextPrimary,
    displayColor: darkTextPrimary,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: darkSurface,
        background: darkBackground,
        surfaceVariant: darkSurfaceVariant,
        onSurface: darkTextPrimary,
        onSurfaceVariant: darkTextSecondary,
        outline: darkOutline,
        error: errorColor,
      ),
      scaffoldBackgroundColor: darkBackground,
      cardTheme: CardTheme(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: darkOutline.withOpacity(0.3)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: darkTextPrimary),
        titleTextStyle: _mainTextTheme.titleLarge?.copyWith(
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: _mainTextTheme.copyWith(
        displayLarge: _mainTextTheme.displayLarge?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        displayMedium: _mainTextTheme.displayMedium?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
        displaySmall: _mainTextTheme.displaySmall?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        headlineLarge: _mainTextTheme.headlineLarge?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
        headlineMedium: _mainTextTheme.headlineMedium?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        headlineSmall: _mainTextTheme.headlineSmall?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        titleLarge: _mainTextTheme.titleLarge?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        titleMedium: _mainTextTheme.titleMedium?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        titleSmall: _mainTextTheme.titleSmall?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        bodyLarge: _mainTextTheme.bodyLarge?.copyWith(
          color: darkTextPrimary,
          fontSize: 15,
        ),
        bodyMedium: _mainTextTheme.bodyMedium?.copyWith(
          color: darkTextPrimary,
          fontSize: 14,
        ),
        bodySmall: _mainTextTheme.bodySmall?.copyWith(
          color: darkTextSecondary,
          fontSize: 13,
        ),
        labelLarge: _mainTextTheme.labelLarge?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        labelMedium: _mainTextTheme.labelMedium?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        labelSmall: _mainTextTheme.labelSmall?.copyWith(
          color: darkTextSecondary,
          fontSize: 12,
        ),
      ),
      iconTheme: const IconThemeData(
        color: darkTextPrimary,
      ),
      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: darkTextSecondary,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceVariant.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkOutline.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkOutline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle:
            _mainTextTheme.bodyMedium?.copyWith(color: darkTextSecondary),
        hintStyle: _mainTextTheme.bodyMedium?.copyWith(color: darkTextHint),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: _mainTextTheme.titleLarge?.copyWith(
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: _mainTextTheme.bodyMedium?.copyWith(
          color: darkTextSecondary,
          fontSize: 14,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCard,
        contentTextStyle:
            _mainTextTheme.bodyMedium?.copyWith(color: darkTextPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: _mainTextTheme.bodyMedium?.copyWith(color: darkTextPrimary),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: darkTextSecondary,
        indicatorColor: primaryColor,
        labelStyle: _mainTextTheme.labelLarge,
        unselectedLabelStyle: _mainTextTheme.labelLarge,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceVariant.withOpacity(0.5),
        selectedColor: primaryColor.withOpacity(0.2),
        disabledColor: darkSurfaceVariant,
        labelStyle:
            _mainTextTheme.labelMedium?.copyWith(color: darkTextPrimary),
        secondaryLabelStyle:
            _mainTextTheme.labelMedium?.copyWith(color: darkTextPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: darkOutline.withOpacity(0.3)),
        ),
      ),
    );
  }

  // Helper method to get journal text theme
  static TextTheme get journalTextTheme => _journalTextTheme;

  // Helper method to get splash text theme
  static TextTheme get splashTextTheme => _splashTextTheme;
}
