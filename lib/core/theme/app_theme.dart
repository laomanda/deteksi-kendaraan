import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import '../constants/app_radius.dart';

/// RideCare Design System Theme Configuration (Single Source of Truth: DESIGN.md)
///
/// Implements Material 3 tailored for Digital Cockpit & Personal Vehicle Companion.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final textTheme = AppTypography.buildRideCareTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        tertiary: AppColors.accent,
        onTertiary: Colors.white,
        surface: AppColors.surfaceWhite,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
        onError: Colors.white,
        outline: AppColors.borderSubtle,
        surfaceContainerHighest: AppColors.surfaceSubtle,
      ),

      // Typography
      textTheme: textTheme,

      // AppBar Theme (Clean digital cockpit style)
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 22,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),

      // Card Theme (Bordered, flat, rounded 16dp)
      cardTheme: CardThemeData(
        color: AppColors.surfaceWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorderRadius,
          side: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
      ),

      // Elevated Button Theme (Midnight Navy primary action)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: AppTypography.labelLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonBorderRadius,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.borderSubtle, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonBorderRadius,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonBorderRadius,
          ),
        ),
      ),

      // Input Decoration Theme (Forms)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: AppRadius.buttonBorderRadius,
          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonBorderRadius,
          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonBorderRadius,
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonBorderRadius,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonBorderRadius,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.modalTopRadius,
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorderRadius,
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceWhite,
        selectedColor: AppColors.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.chipBorderRadius,
          side: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
        labelStyle: AppTypography.labelMedium,
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        indicatorColor: AppColors.accent.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.captionBadge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            );
          }
          return AppTypography.captionBadge.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 22);
          }
          return const IconThemeData(color: AppColors.textSecondary, size: 22);
        }),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.buttonBorderRadius,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
