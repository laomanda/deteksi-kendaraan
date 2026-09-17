import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// RideCare Typography System (Single Source of Truth: DESIGN.md)
///
/// Fonts:
/// - Primary UI: Plus Jakarta Sans (body, button, label, nav, form, heading)
/// - Display / Metrics: Space Grotesk (odometer, km metrics, brand, digital cockpit)
/// - Accent: Manrope (onboarding, marketing, premium cards)
class AppTypography {
  AppTypography._();

  // ==========================================
  // 1. FONT FAMILY GETTERS (google_fonts)
  // ==========================================
  static TextStyle get primaryFont => GoogleFonts.plusJakartaSans();
  static TextStyle get displayFont => GoogleFonts.spaceGrotesk();
  static TextStyle get accentFont => GoogleFonts.manrope();

  // ==========================================
  // 2. DISPLAY STYLES (Space Grotesk - Metrics & Cockpit)
  // ==========================================
  /// Hero kilometer / Large digital metric (36px, w800)
  static TextStyle get displayHero => GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: AppColors.textPrimary,
        height: 1.15,
      );

  /// Major statistics & Display Large (32px, w700)
  static TextStyle get displayLarge => GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  /// Display Medium (28px, w700)
  static TextStyle get displayMedium => GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  /// Display Small (24px, w700)
  static TextStyle get displaySmall => GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  /// Metric Value (20px, w700) - For telemetry HUD numbers
  static TextStyle get metricValue => GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  // ==========================================
  // 3. HEADLINE & TITLE STYLES (Plus Jakarta Sans)
  // ==========================================
  /// Headline Large / Hero title (24px, w800)
  static TextStyle get headlineLarge => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  /// Headline Medium / Heading 1 (22px, w700)
  static TextStyle get headlineMedium => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  /// Title Large / Heading 2 (18px, w700)
  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
        height: 1.35,
      );

  /// Title Medium / Heading 3 (16px, w600)
  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  /// Title Small (14px, w600)
  static TextStyle get titleSmall => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  // ==========================================
  // 4. BODY STYLES (Plus Jakarta Sans)
  // ==========================================
  /// Body Large (16px, w400)
  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  /// Body Medium / Standard Paragraph (14px, w400)
  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: AppColors.textPrimary,
        height: 1.45,
      );

  /// Body Small / Secondary description (12px, w500)
  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  // ==========================================
  // 5. LABEL & CAPTION STYLES (Plus Jakarta Sans)
  // ==========================================
  /// Button Label / Interactive (14px, w600)
  static TextStyle get labelLarge => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: AppColors.textPrimary,
      );

  /// Chip / Filter Label (12px, w600)
  static TextStyle get labelMedium => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: AppColors.textSecondary,
      );

  /// Badge / Status Label (11px, w600)
  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: AppColors.textPrimary,
      );

  /// Caption Badge (11px, w600)
  static TextStyle get captionBadge => labelSmall;

  /// Caption Subtle (10px, w400)
  static TextStyle get captionSubtle => GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: AppColors.textMuted,
        height: 1.3,
      );

  // ==========================================
  // 6. ACCENT STYLES (Manrope - Onboarding / Marketing)
  // ==========================================
  /// Onboarding Hero Title (28px, w800)
  static TextStyle get accentHero => GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  /// Onboarding Subtitle / Story (15px, w500)
  static TextStyle get accentSubtitle => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  // ==========================================
  // 7. BACKWARD COMPATIBLE ALIASES
  // ==========================================
  static TextStyle get heading1 => headlineMedium;
  static TextStyle get heading2 => titleLarge;
  static TextStyle get heading3 => titleMedium;

  // ==========================================
  // 8. MATERIAL 3 TEXT THEME BUILDER
  // ==========================================
  static TextTheme buildRideCareTextTheme() {
    return TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: displaySmall,
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: titleLarge,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: titleSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    );
  }
}

/// Token collection alias for AppTypography
typedef AppTextStyle = AppTypography;
