import 'package:flutter/material.dart';
import 'package:spendwise/core/constants/app_constants.dart';
import 'package:spendwise/domain/models/enums.dart';

abstract final class AppTheme {
  static ThemeData lightTheme([String colorTheme = 'gold']) =>
      _theme(Brightness.light, colorTheme);
  static ThemeData darkTheme([String colorTheme = 'gold']) =>
      _theme(Brightness.dark, colorTheme);
  static ThemeData _theme(Brightness brightness, String colorTheme) {
    final palette = AppColorThemes.forId(colorTheme);
    final generated = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: brightness,
    );
    final dark = brightness == Brightness.dark;
    final scheme = generated.copyWith(
      primary: dark ? palette.primaryDark : palette.primary,
      secondary: palette.secondary,
      surface: dark ? palette.darkSurface : const Color(0xFFF5F7FB),
      surfaceContainer: dark ? palette.darkContainer : const Color(0xFFFFFFFF),
      surfaceContainerHigh: dark
          ? palette.darkContainerHigh
          : const Color(0xFFF0F3F8),
      outlineVariant: dark ? const Color(0xFF30333A) : const Color(0xFFDDE2EA),
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
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
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
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
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
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
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
    required this.darkSurface,
    required this.darkContainer,
    required this.darkContainerHigh,
  });

  final String id;
  final String name;
  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color darkSurface;
  final Color darkContainer;
  final Color darkContainerHigh;
}

abstract final class AppColorThemes {
  static const gold = AppColorTheme(
    id: 'gold',
    name: 'Gold',
    primary: Color(0xFFB88A19),
    primaryDark: Color(0xFFE3B94F),
    secondary: Color(0xFFF2D27A),
    darkSurface: Color(0xFF10100F),
    darkContainer: Color(0xFF1B1B18),
    darkContainerHigh: Color(0xFF272620),
  );
  static const ocean = AppColorTheme(
    id: 'ocean',
    name: 'Oceano',
    primary: Color(0xFF2563EB),
    primaryDark: Color(0xFF3C96FF),
    secondary: Color(0xFF7C3AED),
    darkSurface: Color(0xFF050608),
    darkContainer: Color(0xFF17191D),
    darkContainerHigh: Color(0xFF202228),
  );
  static const emerald = AppColorTheme(
    id: 'emerald',
    name: 'Smeraldo',
    primary: Color(0xFF078A67),
    primaryDark: Color(0xFF24C79A),
    secondary: Color(0xFF7DE2C2),
    darkSurface: Color(0xFF07100D),
    darkContainer: Color(0xFF12201B),
    darkContainerHigh: Color(0xFF1B2D27),
  );

  static const values = [gold, ocean, emerald];

  static AppColorTheme forId(String id) =>
      values.where((theme) => theme.id == id).firstOrNull ?? gold;
}

abstract final class CategoryColors {
  static Color forType(CategoryType type) => switch (type) {
    CategoryType.daily => AppColors.daily,
    CategoryType.subscription => AppColors.subscription,
    CategoryType.installment => AppColors.installment,
    CategoryType.vehicle => AppColors.vehicle,
  };
}
