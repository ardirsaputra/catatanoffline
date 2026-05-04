import 'package:flutter/material.dart';
import 'color_schemes.dart';

class AppTheme {
  static ThemeData build({
    required AppColorScheme scheme,
    required bool isDark,
    required String fontSize, // small, medium, large
    Color? customPrimaryColor,
  }) {
    final palette = AppColorSchemes.getPalette(scheme);
    final colorScheme = AppColorSchemes.buildMaterial3Scheme(palette, isDark);

    final textScaleFactor = switch (fontSize) {
      'small' => 0.85,
      'large' => 1.15,
      _ => 1.0,
    };

    final baseTextTheme = ThemeData.light().textTheme.apply(fontFamily: 'Poppins');
    final scaledTextTheme = _scaleTextTheme(baseTextTheme, textScaleFactor);
    final textTheme = isDark
        ? scaledTextTheme.apply(
            bodyColor: const Color(0xFFE0E0E0),
            displayColor: const Color(0xFFE0E0E0),
          )
        : scaledTextTheme.apply(
            bodyColor: const Color(0xFF3D3D3D),
            displayColor: const Color(0xFF3D3D3D),
          );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : palette.background,
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        surfaceTintColor: Colors.transparent,
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : palette.primary,
        foregroundColor: const Color(0xFF3D3D3D),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18 * textScaleFactor,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF3D3D3D),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF3D3D3D)),
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        selectedItemColor: palette.primary,
        unselectedItemColor: const Color(0xFF9E9E9E),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11 * textScaleFactor,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11 * textScaleFactor,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: const Color(0xFF3D3D3D),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF2A2A3E) : palette.primary.withOpacity(0.15),
        selectedColor: palette.primary,
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12 * textScaleFactor,
          color: const Color(0xFF3D3D3D),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF3A3A55) : const Color(0xFFE0E0E0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(
          fontFamily: 'Poppins',
          color: const Color(0xFF9E9E9E),
          fontSize: 14 * textScaleFactor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: const Color(0xFF3D3D3D),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14 * textScaleFactor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? palette.primary : const Color(0xFF3D3D3D),
          side: BorderSide(color: palette.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14 * textScaleFactor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          textStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14 * textScaleFactor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        thickness: 1,
        color: Color(0xFFEEEEEE),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF2A2A3E) : const Color(0xFF333333),
        contentTextStyle: TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontSize: 13 * textScaleFactor,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        elevation: 8,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18 * textScaleFactor,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF3D3D3D),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.primary;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.primary.withOpacity(0.5);
          }
          return null;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.primary;
          return null;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.primary;
          return null;
        }),
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      extensions: [
        AppColorExtension(
          primary: palette.primary,
          secondary: palette.secondary,
          accent: palette.accent,
          cardBackground: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          subtleBackground: isDark ? const Color(0xFF2A2A3E) : palette.background,
        ),
      ],
    );
  }

  static TextTheme _scaleTextTheme(TextTheme base, double factor) {
    return TextTheme(
      displayLarge: base.displayLarge?.copyWith(fontSize: (base.displayLarge?.fontSize ?? 57) * factor),
      displayMedium: base.displayMedium?.copyWith(fontSize: (base.displayMedium?.fontSize ?? 45) * factor),
      displaySmall: base.displaySmall?.copyWith(fontSize: (base.displaySmall?.fontSize ?? 36) * factor),
      headlineLarge: base.headlineLarge?.copyWith(fontSize: (base.headlineLarge?.fontSize ?? 32) * factor),
      headlineMedium: base.headlineMedium?.copyWith(fontSize: (base.headlineMedium?.fontSize ?? 28) * factor),
      headlineSmall: base.headlineSmall?.copyWith(fontSize: (base.headlineSmall?.fontSize ?? 24) * factor),
      titleLarge: base.titleLarge?.copyWith(fontSize: (base.titleLarge?.fontSize ?? 22) * factor),
      titleMedium: base.titleMedium?.copyWith(fontSize: (base.titleMedium?.fontSize ?? 16) * factor),
      titleSmall: base.titleSmall?.copyWith(fontSize: (base.titleSmall?.fontSize ?? 14) * factor),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: (base.bodyLarge?.fontSize ?? 16) * factor),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: (base.bodyMedium?.fontSize ?? 14) * factor),
      bodySmall: base.bodySmall?.copyWith(fontSize: (base.bodySmall?.fontSize ?? 12) * factor),
      labelLarge: base.labelLarge?.copyWith(fontSize: (base.labelLarge?.fontSize ?? 14) * factor),
      labelMedium: base.labelMedium?.copyWith(fontSize: (base.labelMedium?.fontSize ?? 12) * factor),
      labelSmall: base.labelSmall?.copyWith(fontSize: (base.labelSmall?.fontSize ?? 11) * factor),
    );
  }
}

class AppColorExtension extends ThemeExtension<AppColorExtension> {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color cardBackground;
  final Color subtleBackground;

  const AppColorExtension({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.cardBackground,
    required this.subtleBackground,
  });

  @override
  ThemeExtension<AppColorExtension> copyWith({
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? cardBackground,
    Color? subtleBackground,
  }) {
    return AppColorExtension(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      cardBackground: cardBackground ?? this.cardBackground,
      subtleBackground: subtleBackground ?? this.subtleBackground,
    );
  }

  @override
  ThemeExtension<AppColorExtension> lerp(
    ThemeExtension<AppColorExtension>? other,
    double t,
  ) {
    if (other is! AppColorExtension) return this;
    return AppColorExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      subtleBackground: Color.lerp(subtleBackground, other.subtleBackground, t)!,
    );
  }
}
