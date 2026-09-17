import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';

/// RideCare UI Validation & Feedback System (Single Source of Truth: DESIGN.md)
///
/// Standards:
/// - Success: [AppColors.success] (#16A34A)
/// - Warning: [AppColors.warning] (#F59E0B)
/// - Danger:  [AppColors.danger]  (#DC2626)
/// - All UI copy in clear, professional Bahasa Indonesia.
class AppFeedback {
  AppFeedback._();

  /// Shows standard floating SnackBar feedback
  static void showSnackBar(
    BuildContext context, {
    required String message,
    FeedbackType type = FeedbackType.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final color = _getColorForType(type);
    final icon = _getIconForType(type);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.space16),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.buttonBorderRadius,
          side: BorderSide(color: color.withValues(alpha: 0.3), width: 1.2),
        ),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        action: action,
        duration: duration,
      ),
    );
  }

  /// Shortcut for Success feedback
  static void showSuccess(BuildContext context, String message) {
    showSnackBar(context, message: message, type: FeedbackType.success);
  }

  /// Shortcut for Warning feedback
  static void showWarning(BuildContext context, String message) {
    showSnackBar(context, message: message, type: FeedbackType.warning);
  }

  /// Shortcut for Danger / Error feedback
  static void showDanger(BuildContext context, String message) {
    showSnackBar(context, message: message, type: FeedbackType.danger);
  }

  // Internal Helpers
  static Color _getColorForType(FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return AppColors.success;
      case FeedbackType.warning:
        return AppColors.warning;
      case FeedbackType.danger:
        return AppColors.danger;
      case FeedbackType.info:
        return AppColors.accent;
    }
  }

  static IconData _getIconForType(FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return Icons.check_circle_rounded;
      case FeedbackType.warning:
        return Icons.warning_amber_rounded;
      case FeedbackType.danger:
        return Icons.error_outline_rounded;
      case FeedbackType.info:
        return Icons.info_outline_rounded;
    }
  }
}

enum FeedbackType {
  success,
  warning,
  danger,
  info,
}
