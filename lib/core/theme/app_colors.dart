import 'package:flutter/material.dart';

/// RideCare Design System Color Tokens (Single Source of Truth: DESIGN.md)
class AppColors {
  AppColors._();

  // ==========================================
  // 1. PRIMARY PALETTE (DESIGN.md)
  // ==========================================
  /// Midnight Navy (#102A43) - Dominant brand color, chassis, dark elements
  static const Color primary = Color(0xFF102A43);
  static const Color primaryNavy = primary;
  static const Color primaryBlue = primary; // Backward compatible alias

  /// Steel Blue (#334E68) - Secondary structure, shadows, housing components
  static const Color secondary = Color(0xFF334E68);
  static const Color secondarySteel = secondary;
  static const Color secondaryTeal = Color(0xFF00A6A6); // Accent alias

  /// Electric Cyan (#00A6A6) - High-tech telemetry accent, active pulse, LED beam
  static const Color accent = Color(0xFF00A6A6);
  static const Color accentCyan = accent;

  /// Warm White (#F7F5EF) - Calm backdrop, paper-tone surface
  static const Color background = Color(0xFFF7F5EF);
  static const Color bgLight = background;

  // ==========================================
  // 2. SURFACES & BORDERS
  // ==========================================
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF0EFEA);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color borderSubtle = Color(0xFFE2DDD5);
  static const Color borderStrong = Color(0xFFCBD2D9);

  // ==========================================
  // 3. TYPOGRAPHY TOKENS
  // ==========================================
  static const Color textPrimary = Color(0xFF102A43);
  static const Color textSecondary = Color(0xFF334E68);
  static const Color textMuted = Color(0xFF829AB1);
  static const Color textWhite = Color(0xFFFFFFFF);

  // ==========================================
  // 4. STATUS & TELEMETRY COLORS (DESIGN.md)
  // ==========================================
  /// Safe / Optimal (#16A34A) - 80% - 100% Health status
  static const Color success = Color(0xFF16A34A);
  static const Color safeGreen = success;
  static const Color healthOptimal = success;
  static const Color successGreen = success;

  /// Warning / Attention (#F59E0B) - 50% - 79% Moderate status
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningAmber = warning;
  static const Color healthModerate = warning;
  static const Color healthWarning = Color(0xFFF97316); // 20% - 49%

  /// Danger / Critical (#DC2626) - 0% - 19% Overdue status
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerRed = danger;
  static const Color healthCritical = danger;

  // ==========================================
  // 5. HELPER METHODS
  // ==========================================
  /// Normalizes any percentage input (0.0 - 1.0 or 0.0 - 100.0) strictly clamped to 0.0 - 100.0.
  static double normalizePercentage(double percentage) {
    if (percentage > 1.0) {
      return percentage.clamp(0.0, 100.0);
    } else {
      return (percentage * 100.0).clamp(0.0, 100.0);
    }
  }

  /// Resolves the health status color according to the percentage (clamped max 100.0)
  static Color getHealthColor(double percentage) {
    final pct = normalizePercentage(percentage);
    if (pct >= 80.0) {
      return healthOptimal;
    } else if (pct >= 50.0) {
      return healthModerate;
    } else if (pct >= 20.0) {
      return healthWarning;
    } else {
      return healthCritical;
    }
  }

  /// Returns textual label in Indonesian for health status (DESIGN.md Section 14.2)
  static String getHealthStatusLabel(double percentage) {
    final pct = normalizePercentage(percentage);
    if (pct >= 80.0) {
      return 'Kondisi Baik';
    } else if (pct >= 50.0) {
      return 'Performa Stabil';
    } else if (pct >= 20.0) {
      return 'Perlu Perhatian';
    } else {
      return 'Jatuh Tempo';
    }
  }
}
