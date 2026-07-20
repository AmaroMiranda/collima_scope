import 'package:flutter/material.dart';

/// Design system "Optical Console" (refatoração visual §3): interface escura,
/// técnica e silenciosa — precisão sem excesso visual. Modo vermelho para
/// preservar a adaptação noturna (sem azuis/verdes/brancos intensos).
class OpticalTokens {
  OpticalTokens._();

  // Paleta principal (§3.2)
  static const background = Color(0xFF06080D);
  static const surface = Color(0xFF10151E);
  static const surfaceElevated = Color(0xFF161D28);
  static const border = Color(0xFF273142);
  static const primary = Color(0xFF54E3E3); // alinhamento / ação principal
  static const secondary = Color(0xFF6DE6A3); // correto / concluído
  static const warning = Color(0xFFF4C95D); // atenção / alinhamento manual
  static const error = Color(0xFFFF6B6B);
  static const textPrimary = Color(0xFFF7FAFC);
  static const textSecondary = Color(0xFFA4AFBE);
  static const textMuted = Color(0xFF707C8C);

  // Formas (§3.5)
  static const cardRadius = 18.0;
  static const buttonRadius = 14.0;
}

class AppTheme {
  static ThemeData dark() {
    final scheme = ColorScheme.dark(
      primary: OpticalTokens.primary,
      onPrimary: const Color(0xFF041012),
      secondary: OpticalTokens.secondary,
      onSecondary: const Color(0xFF041012),
      surface: OpticalTokens.surface,
      onSurface: OpticalTokens.textPrimary,
      onSurfaceVariant: OpticalTokens.textSecondary,
      outline: OpticalTokens.border,
      error: OpticalTokens.error,
      tertiary: OpticalTokens.warning,
    );
    return _base(scheme, OpticalTokens.background, OpticalTokens.border);
  }

  /// Modo vermelho (§3.3): reduz componentes azuis/verdes/brancos, não só
  /// troca a cor primária.
  static ThemeData red() {
    const primary = Color(0xFFF05A47);
    const text = Color(0xFFFF8C7D);
    const textSecondary = Color(0xFFB94B3D);
    const border = Color(0xFF4B1711);
    final scheme = ColorScheme.dark(
      primary: primary,
      onPrimary: const Color(0xFF120303),
      secondary: const Color(0xFFB94B3D),
      onSecondary: const Color(0xFF120303),
      surface: const Color(0xFF160503),
      onSurface: text,
      onSurfaceVariant: textSecondary,
      outline: border,
      error: const Color(0xFFFF6B5B),
      tertiary: const Color(0xFFD47A3A),
    );
    return _base(scheme, const Color(0xFF050000), border).copyWith(
      textTheme: _base(scheme, const Color(0xFF050000), border)
          .textTheme
          .apply(bodyColor: text, displayColor: text),
      iconTheme: const IconThemeData(color: text),
      dividerColor: border,
    );
  }

  static ThemeData _base(ColorScheme scheme, Color background, Color border) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OpticalTokens.cardRadius),
          side: BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(OpticalTokens.buttonRadius)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(OpticalTokens.buttonRadius)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
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
      expansionTileTheme: const ExpansionTileThemeData(
        shape: Border(),
        collapsedShape: Border(),
      ),
    );
  }
}
