import 'package:flutter/material.dart';
import 'package:spendwise/core/constants/app_constants.dart';
import 'package:spendwise/domain/models/enums.dart';

abstract final class AppTheme {
  static ThemeData lightTheme([String colorTheme = 'ocean']) =>
      _theme(Brightness.light, colorTheme);
  static ThemeData darkTheme([String colorTheme = 'ocean']) =>
      _theme(Brightness.dark, colorTheme);
  static ThemeData _theme(Brightness brightness, String colorTheme) {
    final palette = AppColorThemes.forId(colorTheme);
    final generated = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: brightness,
    );
    final dark = brightness == Brightness.dark;
    final scheme = generated.copyWith(
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      secondary: palette.secondary,
      surface: dark ? palette.darkSurface : const Color(0xFFF5F7FB),
      surfaceContainer: dark ? palette.darkContainer : const Color(0xFFFFFFFF),
      surfaceContainerHigh: dark
          ? palette.darkContainerHigh
          : const Color(0xFFF0F3F8),
      onSurface: dark ? palette.textPrimary : const Color(0xFF14171D),
      onSurfaceVariant: dark ? palette.textSecondary : const Color(0xFF5E6572),
      outline: dark ? palette.border : const Color(0xFFC9D0DA),
      outlineVariant: dark ? palette.border : const Color(0xFFDDE2EA),
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Inter',
      brightness: brightness,
    );
    final text = base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.bold,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.bold,
      ),
    );
    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.75),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: .55),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(palette.onPrimary),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? scheme.onSurface.withValues(alpha: .12)
                : states.contains(WidgetState.hovered)
                ? palette.primaryHover
                : palette.primary,
          ),
          overlayColor: WidgetStatePropertyAll(
            palette.onPrimary.withValues(alpha: .08),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          animationDuration: const Duration(milliseconds: 160),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? scheme.onSurface.withValues(alpha: .38)
                : scheme.onSurface,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.hovered)
                  ? scheme.primary
                  : scheme.outlineVariant,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          animationDuration: const Duration(milliseconds: 160),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: scheme.surface,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: scheme.surfaceContainer.withValues(alpha: .96),
        indicatorColor: scheme.primary.withValues(alpha: .18),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
            fontSize: 10.5,
            height: 1,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primary.withValues(alpha: .18),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: TextStyle(color: scheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class AppColorTheme {
  const AppColorTheme({
    required this.id,
    required this.name,
    required this.primary,
    required this.primaryDark,
    required this.secondary,
    required this.primaryHover,
    required this.onPrimary,
    required this.darkSurface,
    required this.darkContainer,
    required this.darkContainerHigh,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
  });

  final String id;
  final String name;
  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color primaryHover;
  final Color onPrimary;
  final Color darkSurface;
  final Color darkContainer;
  final Color darkContainerHigh;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
}

abstract final class AppColorThemes {
  static const gold = AppColorTheme(
    id: 'gold',
    name: 'Gold',
    primary: Color(0xFFC9A227),
    primaryDark: Color(0xFFC9A227),
    primaryHover: Color(0xFFD8B44A),
    onPrimary: Color(0xFF17130A),
    secondary: Color(0xFFD8B44A),
    darkSurface: Color(0xFF0F0F0F),
    darkContainer: Color(0xFF181818),
    darkContainerHigh: Color(0xFF222222),
    border: Color(0xFF2D2A22),
    textPrimary: Color(0xFFF5F1E8),
    textSecondary: Color(0xFFA7A29A),
  );
  static const ocean = AppColorTheme(
    id: 'ocean',
    name: 'Oceano',
    primary: Color(0xFF2563EB),
    primaryDark: Color(0xFF2563EB),
    primaryHover: Color(0xFF3B82F6),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF7C3AED),
    darkSurface: Color(0xFF060A12),
    darkContainer: Color(0xFF17191D),
    darkContainerHigh: Color(0xFF202228),
    border: Color(0xFF293445),
    textPrimary: Color(0xFFF5F8FF),
    textSecondary: Color(0xFF9DA8B8),
  );
  static const emerald = AppColorTheme(
    id: 'emerald',
    name: 'Emerald',
    primary: Color(0xFF10B981),
    primaryDark: Color(0xFF10B981),
    primaryHover: Color(0xFF34D399),
    onPrimary: Color(0xFF04120C),
    secondary: Color(0xFF34D399),
    darkSurface: Color(0xFF07110D),
    darkContainer: Color(0xFF101C17),
    darkContainerHigh: Color(0xFF172820),
    border: Color(0xFF1F332B),
    textPrimary: Color(0xFFF3FFF8),
    textSecondary: Color(0xFF9CAFA6),
  );

  static const violet = AppColorTheme(
    id: 'violet',
    name: 'Violet',
    primary: Color(0xFF8B5CF6),
    primaryDark: Color(0xFF8B5CF6),
    primaryHover: Color(0xFFA78BFA),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFA78BFA),
    darkSurface: Color(0xFF0D0A14),
    darkContainer: Color(0xFF171221),
    darkContainerHigh: Color(0xFF21192F),
    border: Color(0xFF2A2038),
    textPrimary: Color(0xFFFAF7FF),
    textSecondary: Color(0xFFAAA0B8),
  );
  static const crimson = AppColorTheme(
    id: 'crimson',
    name: 'Crimson',
    primary: Color(0xFFE11D48),
    primaryDark: Color(0xFFE11D48),
    primaryHover: Color(0xFFFB7185),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFFB7185),
    darkSurface: Color(0xFF12080A),
    darkContainer: Color(0xFF1D1013),
    darkContainerHigh: Color(0xFF28161A),
    border: Color(0xFF3A2025),
    textPrimary: Color(0xFFFFF5F7),
    textSecondary: Color(0xFFB8A0A5),
  );
  static const graphite = AppColorTheme(
    id: 'graphite',
    name: 'Graphite',
    primary: Color(0xFFE5E7EB),
    primaryDark: Color(0xFFE5E7EB),
    primaryHover: Color(0xFFFFFFFF),
    onPrimary: Color(0xFF111318),
    secondary: Color(0xFF9CA3AF),
    darkSurface: Color(0xFF0B0D10),
    darkContainer: Color(0xFF17191D),
    darkContainerHigh: Color(0xFF202328),
    border: Color(0xFF2A2D33),
    textPrimary: Color(0xFFF9FAFB),
    textSecondary: Color(0xFF9CA3AF),
  );

  static const values = [ocean, gold, emerald, violet, crimson, graphite];

  static AppColorTheme forId(String id) =>
      values.where((theme) => theme.id == id).firstOrNull ?? ocean;
}

abstract final class CategoryColors {
  static Color forType(CategoryType type) => switch (type) {
    CategoryType.daily => AppColors.daily,
    CategoryType.subscription => AppColors.subscription,
    CategoryType.installment => AppColors.installment,
    CategoryType.vehicle => AppColors.vehicle,
  };
}
