import 'package:flutter/material.dart';

/// RideCare Design System Color Tokens (DSS Table 3 & Table 4)
class AppColors {
  AppColors._();

  // Primary & Secondary Brand Colors
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color secondaryTeal = Color(0xFF14B8A6);

  // Backgrounds & Surfaces
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF1F5F9);
  static const Color borderSubtle = Color(0xFFE2E8F0);

  // Typography Tokens
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Health Status Tokens (DSS Table 4)
  static const Color healthOptimal = Color(0xFF10B981); // 80% - 100%
  static const Color successGreen = healthOptimal;
  static const Color healthModerate = Color(0xFFF59E0B); // 50% - 79%
  static const Color healthWarning = Color(0xFFF97316); // 20% - 49%
  static const Color healthCritical = Color(0xFFEF4444); // 0% - 19%

  /// Normalizes any percentage input (whether 0.0 - 1.0 fraction or 0.0 - 100.0 scale)
  /// to guaranteed 0.0 to 100.0 scale, strictly clamped between 0.0 and 100.0.
  static double normalizePercentage(double percentage) {
    if (percentage > 1.0) {
      return percentage.clamp(0.0, 100.0);
    } else {
      return (percentage * 100.0).clamp(0.0, 100.0);
    }
  }

  /// Resolves the health status color according to the percentage (accepts 0.0 - 1.0 or 0.0 - 100.0)
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

  /// Returns textual label in Indonesian for health status (DSS Section 14.2)
  /// Accepts 0.0 - 1.0 or 0.0 - 100.0, never exceeding 100.0.
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
