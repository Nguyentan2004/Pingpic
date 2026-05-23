import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static List<BoxShadow> neonGlowShadow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.4),
          blurRadius: 16,
          offset: const Offset(0, 4),
          spreadRadius: 1,
        ),
      ];

  static List<BoxShadow> softShadow() => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> getShadow(BuildContext context, {Color? darkColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? neonGlowShadow(darkColor ?? AppColors.primary) : softShadow();
  }

  static TextTheme get _textTheme =>
      GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w800),
        displayMedium: GoogleFonts.inter(fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(),
        bodyMedium: GoogleFonts.inter(),
        labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w600),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
          surface: Colors.white,
          onSurface: AppColors.textDark,
        ),
        scaffoldBackgroundColor: AppColors.lightBackground,
        cardColor: Colors.white,
        dividerColor: Colors.black.withOpacity(0.08),
        textTheme: _textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          titleTextStyle: GoogleFonts.inter(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: AppColors.primary,
          surface: AppColors.darkSurface,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        cardColor: AppColors.darkCard,
        dividerColor: Colors.white.withOpacity(0.08),
        textTheme: _textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkSurface,
          elevation: 0,
          titleTextStyle: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
      );
}
