import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// App theme configuration — Premium Midnight UI
abstract final class AppTheme {
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // ─── Colors ────────────────────────────────────────
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,

      // ─── Page Transitions ───────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      // ─── Typography ────────────────────────────────────
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        titleMedium: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: AppColors.textTertiary,
        ),
        labelLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),

      // ─── AppBar ────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
      ),

      // ─── Bottom Nav ────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background, // Match background for seamless look
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
      ),

      // ─── Cards ─────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // ─── Buttons ───────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // ─── Input ─────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textTertiary,
          fontSize: 15,
        ),
      ),

      // ─── Divider ───────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 0,
      ),

      // ─── Bottom Sheet ──────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        elevation: 24,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // ─── Chip ──────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        side: const BorderSide(color: AppColors.border, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      
      // ─── Floating Action Button ────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
