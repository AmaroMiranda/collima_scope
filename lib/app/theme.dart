import 'package:flutter/material.dart';

/// Temas do CollimaScope (spec §20): escuro por padrão e modo vermelho
/// para preservar a adaptação noturna da visão.
class AppTheme {
  static const _background = Color(0xFF05070D);
  static const _surface = Color(0xFF12161F);
  static const _accent = Color(0xFF37E2E2);

  static ThemeData dark() {
    final scheme = ColorScheme.dark(
      primary: _accent,
      onPrimary: Colors.black,
      secondary: const Color(0xFF34D17B),
      onSecondary: Colors.black,
      surface: _surface,
      onSurface: Colors.white,
      error: const Color(0xFFE0483E),
      tertiary: const Color(0xFFF2C74B),
    );
    return _base(scheme, _background);
  }

  static ThemeData red() {
    const redSoft = Color(0xFFE05545);
    const redDark = Color(0xFF3A0F0A);
    final scheme = ColorScheme.dark(
      primary: redSoft,
      onPrimary: Colors.black,
      secondary: const Color(0xFFB33A2B),
      onSecondary: Colors.black,
      surface: const Color(0xFF190805),
      onSurface: redSoft,
      error: const Color(0xFFFF6B5B),
      tertiary: const Color(0xFFCC7A2E),
    );
    return _base(scheme, Colors.black).copyWith(
      textTheme: _base(scheme, Colors.black)
          .textTheme
          .apply(bodyColor: redSoft, displayColor: redSoft),
      iconTheme: const IconThemeData(color: redSoft),
      dividerColor: redDark,
    );
  }

  static ThemeData _base(ColorScheme scheme, Color background) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
    );
  }
}
