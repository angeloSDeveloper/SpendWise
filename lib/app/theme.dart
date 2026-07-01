import 'package:flutter/material.dart';
import 'package:spendwise/core/constants/app_constants.dart';
import 'package:spendwise/domain/models/enums.dart';

abstract final class AppTheme {
  static ThemeData lightTheme() => _theme(Brightness.light);
  static ThemeData darkTheme() => _theme(Brightness.dark);
  static ThemeData _theme(Brightness brightness) {
    final generated = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    );
    final dark = brightness == Brightness.dark;
    final scheme = generated.copyWith(
      primary: dark ? const Color(0xFF3C96FF) : AppColors.primary,
      surface: dark ? const Color(0xFF050608) : const Color(0xFFF5F7FB),
      surfaceContainer: dark
          ? const Color(0xFF17191D)
          : const Color(0xFFFFFFFF),
      surfaceContainerHigh: dark
          ? const Color(0xFF202228)
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
        indicatorColor: AppColors.primary.withValues(alpha: .18),
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

abstract final class CategoryColors {
  static Color forType(CategoryType type) => switch (type) {
    CategoryType.daily => AppColors.daily,
    CategoryType.subscription => AppColors.subscription,
    CategoryType.installment => AppColors.installment,
    CategoryType.vehicle => AppColors.vehicle,
  };
}
