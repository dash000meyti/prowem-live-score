import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF05070A);
  static const surface = Color(0x8C12161E);
  static const elevated = Color(0xB81C222E);
  static const border = Color(0x1FFFFFFF);
  static const coral = Color(0xFFFF6B3D);
  static const coralDeep = Color(0xFFE54826);
  static const orange = Color(0xFFFF7A18);
  static const cyan = Color(0xFF00D4FF);
  static const purple = Color(0xFFA78BFA);
  static const lime = Color(0xFF39FF6A);
  static const warning = Color(0xFFF5A524);
  static const danger = Color(0xFFFF3B4E);
  static const muted = Color(0xFF9AA3B2);
}

abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.coral,
          secondary: AppColors.orange,
          surface: AppColors.surface,
          error: AppColors.danger,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -.2),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AppColors.border),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.coral,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 52),
            shape: const StadiumBorder(),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: AppColors.border),
            shape: const StadiumBorder(),
          ),
        ),
        progressIndicatorTheme:
            const ProgressIndicatorThemeData(color: AppColors.coral),
        dividerTheme: const DividerThemeData(color: AppColors.border),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0x660D1117),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          hintStyle: const TextStyle(color: AppColors.muted),
          prefixIconColor: AppColors.muted,
          suffixIconColor: AppColors.muted,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.coral),
          ),
        ),
      );
}
