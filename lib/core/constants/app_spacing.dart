import 'package:flutter/material.dart';
import 'app_colors.dart';

/// RideCare Spacing, Radius, and Contour System (DSS Section 7)
class AppSpacing {
  AppSpacing._();

  // Spacing Tokens (DSS Table 6)
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // Radius Tokens (DSS Section 7.2)
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
  static const double chipRadius = 8.0;
  static const double modalRadius = 24.0;

  static final BorderRadius cardBorderRadius = BorderRadius.circular(cardRadius);
  static final BorderRadius buttonBorderRadius = BorderRadius.circular(buttonRadius);
  static final BorderRadius chipBorderRadius = BorderRadius.circular(chipRadius);
  static const BorderRadius modalTopRadius = BorderRadius.vertical(top: Radius.circular(modalRadius));

  // Elevation & Border Rules (DSS Section 7.3)
  static final Border cardBorder = Border.all(
    color: AppColors.borderSubtle,
    width: 1.0,
  );

  static const List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Color.fromRGBO(15, 23, 42, 0.08),
      blurRadius: 12.0,
      offset: Offset(0, 4),
    ),
  ];

  // Touch Target Minimum (DSS Section 14.1)
  static const double minTouchTarget = 48.0;
}
