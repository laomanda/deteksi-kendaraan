import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// RideCare Animation System (Single Source of Truth: DESIGN.md)
///
/// Guidelines:
/// - Subtle, purposeful, high performance
/// - No excessive bouncing or long delays
class AppAnimations {
  AppAnimations._();

  // Standard Durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);

  // Standard Curves
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve snappyCurve = Curves.easeOutQuint;
  static const Curve smoothCurve = Curves.easeInOutCubic;
}

/// Helper extension methods on Widget for rapid, consistent animate styling
extension RideCareAnimationExtension on Widget {
  /// Entrance animation for cards and vertical sections
  Widget entranceSlideUp({
    Duration duration = AppAnimations.medium,
    Duration delay = Duration.zero,
    double offset = 16.0,
  }) {
    return animate(delay: delay)
        .fadeIn(duration: duration, curve: AppAnimations.defaultCurve)
        .slideY(
          begin: offset / 100,
          end: 0,
          duration: duration,
          curve: AppAnimations.defaultCurve,
        );
  }

  /// Entrance animation for horizontal elements / carousels
  Widget entranceSlideX({
    Duration duration = AppAnimations.medium,
    Duration delay = Duration.zero,
    double offset = 20.0,
  }) {
    return animate(delay: delay)
        .fadeIn(duration: duration, curve: AppAnimations.defaultCurve)
        .slideX(
          begin: offset / 100,
          end: 0,
          duration: duration,
          curve: AppAnimations.defaultCurve,
        );
  }

  /// Subtle scale pop for badges, dialogs, and interactive pills
  Widget entrancePop({
    Duration duration = AppAnimations.normal,
    Duration delay = Duration.zero,
  }) {
    return animate(delay: delay)
        .fadeIn(duration: duration)
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1.0, 1.0),
          duration: duration,
          curve: AppAnimations.snappyCurve,
        );
  }

  /// Staggered item entrance for list items
  Widget staggerItem(int index, {int stepMs = 50}) {
    return entranceSlideUp(
      delay: Duration(milliseconds: index * stepMs),
    );
  }
}
