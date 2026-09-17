import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_radius.dart';

/// RideCare Spacing, Gap, and Elevation System (Single Source of Truth: DESIGN.md)
class AppSpacing {
  AppSpacing._();

  // ==========================================
  // 1. SPACING TOKENS (dp)
  // ==========================================
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;

  // Backward Compatible Aliases
  static const double space4 = spacing4;
  static const double space8 = spacing8;
  static const double space12 = spacing12;
  static const double space16 = spacing16;
  static const double space20 = spacing20;
  static const double space24 = spacing24;
  static const double space32 = spacing32;
  static const double space48 = spacing48;

  // Touch Target (48.0dp)
  static const double minTouchTarget = 48.0;

  // ==========================================
  // 2. GAP WIDGETS (SizedBox)
  // ==========================================
  static const SizedBox gap4 = SizedBox(width: spacing4, height: spacing4);
  static const SizedBox gap8 = SizedBox(width: spacing8, height: spacing8);
  static const SizedBox gap12 = SizedBox(width: spacing12, height: spacing12);
  static const SizedBox gap16 = SizedBox(width: spacing16, height: spacing16);
  static const SizedBox gap24 = SizedBox(width: spacing24, height: spacing24);
  static const SizedBox gap32 = SizedBox(width: spacing32, height: spacing32);

  static const SizedBox gapH4 = SizedBox(height: spacing4);
  static const SizedBox gapH8 = SizedBox(height: spacing8);
  static const SizedBox gapH12 = SizedBox(height: spacing12);
  static const SizedBox gapH16 = SizedBox(height: spacing16);
  static const SizedBox gapH24 = SizedBox(height: spacing24);
  static const SizedBox gapH32 = SizedBox(height: spacing32);

  static const SizedBox gapW4 = SizedBox(width: spacing4);
  static const SizedBox gapW8 = SizedBox(width: spacing8);
  static const SizedBox gapW12 = SizedBox(width: spacing12);
  static const SizedBox gapW16 = SizedBox(width: spacing16);
  static const SizedBox gapW24 = SizedBox(width: spacing24);
  static const SizedBox gapW32 = SizedBox(width: spacing32);

  // ==========================================
  // 3. EDGE INSETS PRESETS
  // ==========================================
  static const EdgeInsets paddingAll8 = EdgeInsets.all(spacing8);
  static const EdgeInsets paddingAll12 = EdgeInsets.all(spacing12);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(spacing16);
  static const EdgeInsets paddingAll24 = EdgeInsets.all(spacing24);

  static const EdgeInsets paddingH16 = EdgeInsets.symmetric(horizontal: spacing16);
  static const EdgeInsets paddingH24 = EdgeInsets.symmetric(horizontal: spacing24);
  static const EdgeInsets paddingV12 = EdgeInsets.symmetric(vertical: spacing12);
  static const EdgeInsets paddingV16 = EdgeInsets.symmetric(vertical: spacing16);

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: spacing20,
    vertical: spacing16,
  );

  // ==========================================
  // 4. RADIUS TOKENS (Referencing AppRadius)
  // ==========================================
  static const double cardRadius = AppRadius.card;
  static const double buttonRadius = AppRadius.button;
  static const double chipRadius = AppRadius.chip;
  static const double modalRadius = AppRadius.modal;

  static final BorderRadius cardBorderRadius = AppRadius.cardBorderRadius;
  static final BorderRadius buttonBorderRadius = AppRadius.buttonBorderRadius;
  static final BorderRadius chipBorderRadius = AppRadius.chipBorderRadius;
  static const BorderRadius modalTopRadius = AppRadius.modalTopRadius;

  // ==========================================
  // 5. BORDERS & SHADOWS
  // ==========================================
  static final Border cardBorder = Border.all(
    color: AppColors.borderSubtle,
    width: 1.0,
  );

  static final Border cardBorderActive = Border.all(
    color: AppColors.accent,
    width: 1.5,
  );

  static const List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Color.fromRGBO(16, 42, 67, 0.06),
      blurRadius: 12.0,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color.fromRGBO(16, 42, 67, 0.10),
      blurRadius: 20.0,
      offset: Offset(0, 8),
    ),
  ];
}
