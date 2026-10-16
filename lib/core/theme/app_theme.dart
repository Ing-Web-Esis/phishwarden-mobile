import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const gold = Color(0xFFE8AC36);
  static const ink = Color(0xFF283F50);
  static const darkBackground = Color(0xFF101F28);
  static const lightBackground = Color(0xFFF5F8FB);
  static const lowRisk = Color(0xFF218151);
  static const mediumRisk = Color(0xFF99730C);
  static const highRisk = Color(0xFFCA4250);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final foreground = dark ? const Color(0xFFF8FAFC) : ink;
    final muted = dark ? const Color(0xFFB8C9D3) : const Color(0xFF526D80);
    final field = dark ? const Color(0xFF1B303E) : Colors.white;
    final outline = dark ? const Color(0xFF426073) : const Color(0xFFCDDBE6);
    final scheme = ColorScheme.fromSeed(seedColor: ink, brightness: brightness)
        .copyWith(
          primary: gold,
          onPrimary: ink,
          surface: dark ? darkBackground : lightBackground,
          surfaceContainerLow: field,
          onSurface: foreground,
          onSurfaceVariant: muted,
          outline: outline,
          surfaceContainerHighest: dark
              ? const Color(0xFF203746)
              : const Color(0xFFE7EEF4),
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.25,
          color: foreground,
          letterSpacing: -.6,
        ),
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: foreground,
          letterSpacing: -.6,
        ),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: foreground),
        bodySmall: TextStyle(fontSize: 12, height: 1.45, color: muted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: field,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIconColor: dark ? gold : ink,
        hintStyle: TextStyle(color: muted, fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: dark ? gold : ink, width: 2),
        ),
        errorMaxLines: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
