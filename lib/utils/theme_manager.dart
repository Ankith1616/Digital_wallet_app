import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeManager {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.dark);

  void toggleTheme(bool isDark) {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void setTheme(ThemeMode mode) {
    themeMode.value = mode;
  }
}

// ═══════════════════════════════════════════
// COSMIC MIDNIGHT Theme — Electric Cyan + Gold
// ═══════════════════════════════════════════
class AppColors {
  // ─── Primary: Electric Cyan ───
  static const Color primary = Color(0xFF00D4FF);
  static const Color primaryLight = Color(0xFF6EE9FF);
  static const Color primaryDark = Color(0xFF0095B6);

  // ─── Gold Accent ───
  static const Color accent = Color(0xFFFFD166);
  static const Color gold = Color(0xFFFFD700);
  static const Color goldDim = Color(0xFFB8960C);

  // ─── Semantic ───
  static const Color success = Color(0xFF00E5A0);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFFF4F6D);

  // ─── Dark Theme Surfaces ───
  static const Color darkBg = Color(0xFF070B1A); // deep space
  static const Color darkSurface = Color(0xFF0D1535); // midnight blue
  static const Color darkCard = Color(0xFF111D45); // nebula card
  static const Color darkBorder = Color(0xFF1E2D60);

  // ─── Light Theme Surfaces ───
  static const Color lightBg = Color(0xFFEFF6FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF8FBFF);

  // ─── Gradients ───
  /// Cyan → deep blue (buttons, FAB, logo)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF0055FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Deep navy → midnight blue (header / login bg)
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF080F2E), Color(0xFF0D1A4A), Color(0xFF091340)],
    begin: Alignment.topLeft,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.55, 1.0],
  );

  /// Nebula: cyan → purple (special hero sections)
  static const LinearGradient nebulaGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF7B2FBE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gold shimmer (premium card)
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppThemes {
  // ── DARK THEME ─────────────────────────────
  static final darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: AppColors.darkBg,
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.darkSurface,
      tertiary: AppColors.primaryLight,
      error: AppColors.error,
    ),
    cardColor: AppColors.darkCard,
    dividerColor: AppColors.darkBorder,
    textTheme: GoogleFonts.spaceGroteskTextTheme(
      ThemeData.dark().textTheme,
    ).apply(bodyColor: Colors.white, displayColor: Colors.white),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Color(0xFF4A5580),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.darkBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );

  // ── LIGHT THEME ────────────────────────────
  static final lightTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: AppColors.lightBg,
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.lightSurface,
      tertiary: AppColors.primaryLight,
      error: AppColors.error,
    ),
    cardColor: AppColors.lightCard,
    textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.light().textTheme)
        .apply(
          bodyColor: const Color(0xFF0A0F2C),
          displayColor: const Color(0xFF0A0F2C),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF0A0F2C)),
      titleTextStyle: TextStyle(
        color: Color(0xFF0A0F2C),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF0A0F2C)),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Color(0xFF8898AA),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
