import 'package:flutter/material.dart';

enum AppColorScheme { biru, lavender, mint, peach, rose }

class PastelPalette {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color onPrimary;
  final Color onBackground;
  final String name;

  const PastelPalette({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.onPrimary,
    required this.onBackground,
    required this.name,
  });
}

class AppColorSchemes {
  static const Map<AppColorScheme, PastelPalette> palettes = {
    AppColorScheme.biru: PastelPalette(
      name: 'Biru',
      primary: Color(0xFFA8D8EA),
      secondary: Color(0xFFFFDFD3),
      accent: Color(0xFFB5EAD7),
      background: Color(0xFFFAFAFA),
      surface: Color(0xFFFFFFFF),
      onPrimary: Color(0xFF3D3D3D),
      onBackground: Color(0xFF3D3D3D),
    ),
    AppColorScheme.lavender: PastelPalette(
      name: 'Lavender',
      primary: Color(0xFFC9B8E8),
      secondary: Color(0xFFE8D5F5),
      accent: Color(0xFFB8D4E8),
      background: Color(0xFFFAFAFA),
      surface: Color(0xFFFFFFFF),
      onPrimary: Color(0xFF3D3D3D),
      onBackground: Color(0xFF3D3D3D),
    ),
    AppColorScheme.mint: PastelPalette(
      name: 'Mint',
      primary: Color(0xFFB5EAD7),
      secondary: Color(0xFFD4F5E9),
      accent: Color(0xFFA8E4D4),
      background: Color(0xFFF5FAFA),
      surface: Color(0xFFFFFFFF),
      onPrimary: Color(0xFF3D3D3D),
      onBackground: Color(0xFF3D3D3D),
    ),
    AppColorScheme.peach: PastelPalette(
      name: 'Peach',
      primary: Color(0xFFFFDFD3),
      secondary: Color(0xFFFFF0E8),
      accent: Color(0xFFFFCCB8),
      background: Color(0xFFFAF8F5),
      surface: Color(0xFFFFFFFF),
      onPrimary: Color(0xFF3D3D3D),
      onBackground: Color(0xFF3D3D3D),
    ),
    AppColorScheme.rose: PastelPalette(
      name: 'Mawar',
      primary: Color(0xFFFFB5C8),
      secondary: Color(0xFFFFD4E0),
      accent: Color(0xFFFF9FB8),
      background: Color(0xFFFAF5F7),
      surface: Color(0xFFFFFFFF),
      onPrimary: Color(0xFF3D3D3D),
      onBackground: Color(0xFF3D3D3D),
    ),
  };

  static PastelPalette getPalette(AppColorScheme scheme) =>
      palettes[scheme] ?? palettes[AppColorScheme.biru]!;

  static AppColorScheme fromString(String name) {
    return AppColorScheme.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AppColorScheme.biru,
    );
  }

  static ColorScheme buildMaterial3Scheme(
    PastelPalette palette,
    bool isDark,
  ) {
    if (isDark) {
      return ColorScheme(
        brightness: Brightness.dark,
        primary: palette.primary,
        onPrimary: const Color(0xFF1A1A2E),
        primaryContainer: palette.primary.withOpacity(0.3),
        onPrimaryContainer: Colors.white,
        secondary: palette.secondary,
        onSecondary: const Color(0xFF1A1A2E),
        secondaryContainer: palette.secondary.withOpacity(0.3),
        onSecondaryContainer: Colors.white,
        tertiary: palette.accent,
        onTertiary: const Color(0xFF1A1A2E),
        tertiaryContainer: palette.accent.withOpacity(0.3),
        onTertiaryContainer: Colors.white,
        error: const Color(0xFFFF6B6B),
        onError: Colors.white,
        errorContainer: const Color(0xFF8B0000),
        onErrorContainer: Colors.white,
        surface: const Color(0xFF1E1E2E),
        onSurface: const Color(0xFFE0E0E0),
        surfaceContainerHighest: const Color(0xFF2A2A3E),
        onSurfaceVariant: const Color(0xFFBBBBCC),
        outline: const Color(0xFF555577),
        outlineVariant: const Color(0xFF3A3A50),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: const Color(0xFFE0E0F0),
        onInverseSurface: const Color(0xFF1A1A2E),
        inversePrimary: palette.primary,
        surfaceTint: palette.primary,
      );
    }
    return ColorScheme(
      brightness: Brightness.light,
      primary: palette.primary,
      onPrimary: const Color(0xFF3D3D3D),
      primaryContainer: palette.primary.withOpacity(0.2),
      onPrimaryContainer: const Color(0xFF1A1A1A),
      secondary: palette.secondary,
      onSecondary: const Color(0xFF3D3D3D),
      secondaryContainer: palette.secondary.withOpacity(0.3),
      onSecondaryContainer: const Color(0xFF1A1A1A),
      tertiary: palette.accent,
      onTertiary: const Color(0xFF3D3D3D),
      tertiaryContainer: palette.accent.withOpacity(0.2),
      onTertiaryContainer: const Color(0xFF1A1A1A),
      error: const Color(0xFFE53935),
      onError: Colors.white,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
      surface: palette.surface,
      onSurface: const Color(0xFF3D3D3D),
      surfaceContainerHighest: const Color(0xFFEEEEEE),
      onSurfaceVariant: const Color(0xFF6D6D6D),
      outline: const Color(0xFFBDBDBD),
      outlineVariant: const Color(0xFFE0E0E0),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: const Color(0xFF2D2D2D),
      onInverseSurface: const Color(0xFFF5F5F5),
      inversePrimary: palette.primary,
      surfaceTint: palette.primary,
    );
  }
}
