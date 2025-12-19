import 'package:flutter/material.dart';

class AppTheme {
  // ---- Core Brand Colors (BoardParty) ----
  // Deep navy background, comfortable for long sessions.
  static const Color navy = Color(0xFF0B1220);
  static const Color navy2 = Color(0xFF0F1A2E);
  static const Color surface = Color(0xFF121E35);

  // Primary: calm blue (main CTAs, selected states)
  static const Color primary = Color(0xFF3B82F6); // blue
  static const Color primary2 = Color(0xFF2563EB); // deeper blue

  // Accents
  static const Color success = Color(0xFF22C55E); // green
  static const Color danger  = Color(0xFFEF4444); // red
  static const Color coinGold = Color(0xFFF59E0B); // gold/amber
  static const Color diamond = Color(0xFF60A5FA); // light blue (diamond)

  // Text
  static const Color textPrimary = Color(0xFFE5E7EB);
  static const Color textSecondary = Color(0xFF9CA3AF);

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
    );

    final colorScheme = const ColorScheme(
      brightness: Brightness.dark,

      primary: primary,
      onPrimary: Colors.white,

      secondary: coinGold,
      onSecondary: Color(0xFF1A1200),

      tertiary: success,
      onTertiary: Color(0xFF05210F),

      error: danger,
      onError: Colors.white,

      surface: surface,
      onSurface: textPrimary,

      // Material3 extras
      surfaceContainerHighest: Color(0xFF18284A),
      onSurfaceVariant: textSecondary,

      outline: Color(0xFF2A3A61),
      shadow: Colors.black,

      inverseSurface: Color(0xFFE5E7EB),
      onInverseSurface: Color(0xFF0B1220),

      inversePrimary: Color(0xFF93C5FD),
      scrim: Colors.black,
    );

    return base.copyWith(
      colorScheme: colorScheme,

      scaffoldBackgroundColor: navy,

      appBarTheme: const AppBarTheme(
        backgroundColor: navy2,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),

      // Card / panels (boardgame table 느낌)
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF22335A)),
        ),
      ),

      // Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: surface,
          foregroundColor: textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: const BorderSide(color: Color(0xFF2A3A61)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF93C5FD),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      // Inputs (login, code input, etc.)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F1A2E),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: const TextStyle(color: textSecondary),
        labelStyle: const TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF22335A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF22335A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: danger),
        ),
      ),

      // Chips (filters, tags)
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: const Color(0xFF0F1A2E),
        selectedColor: const Color(0xFF1E3A8A),
        labelStyle: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        side: const BorderSide(color: Color(0xFF22335A)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),

      // BottomNavigationBar (S/H/F)
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: navy2,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),

      // Snackbars / dialogs
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF18284A),
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(color: textPrimary),
      ),

      // Typography (기본값으로도 충분하지만 살짝 정리)
      textTheme: base.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
    );
  }
}