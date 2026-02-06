import 'package:flutter/material.dart';

class AppColors {
  static const Color emerald = Color(0xFF059669);
  static const Color alabaster = Color(0xFFFAF9F6);
  static const Color slateDark = Color(0xFF0F172A);
  static const Color slateLight = Color(0xFF64748B);
  static const Color white = Color(0xFFFFFFFF);
}

ThemeData getAppTheme() {
  final baseTheme = ThemeData.light();
  
  return baseTheme.copyWith(
    primaryColor: AppColors.emerald,
    scaffoldBackgroundColor: AppColors.alabaster,
    colorScheme: baseTheme.colorScheme.copyWith(
      primary: AppColors.emerald,
      background: AppColors.alabaster,
      surface: AppColors.white,
    ),
    appBarTheme: baseTheme.appBarTheme.copyWith(
      backgroundColor: AppColors.alabaster,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.slateDark),
      titleTextStyle: const TextStyle(
        color: AppColors.slateDark,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: baseTheme.cardTheme.copyWith(
      color: AppColors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      margin: const EdgeInsets.all(16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.emerald,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        side: const BorderSide(color: AppColors.emerald),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: AppColors.slateLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: AppColors.emerald),
      ),
      contentPadding: EdgeInsets.all(20),
    ),
  );
}