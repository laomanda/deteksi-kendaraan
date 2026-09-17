import 'package:flutter/material.dart';

/// RideCare Radius System (Single Source of Truth: DESIGN.md)
class AppRadius {
  AppRadius._();

  // Raw Numeric Values (dp)
  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double chip = 8.0;
  static const double md = 12.0;
  static const double button = 12.0;
  static const double card = 16.0;
  static const double container = 16.0;
  static const double lg = 20.0;
  static const double modal = 24.0;
  static const double full = 999.0;
  static const double pill = 999.0;

  // BorderRadius Helpers
  static final BorderRadius chipBorderRadius = BorderRadius.circular(chip);
  static final BorderRadius buttonBorderRadius = BorderRadius.circular(button);
  static final BorderRadius cardBorderRadius = BorderRadius.circular(card);
  static final BorderRadius containerBorderRadius = BorderRadius.circular(container);
  static final BorderRadius modalBorderRadius = BorderRadius.circular(modal);
  static const BorderRadius modalTopRadius = BorderRadius.vertical(top: Radius.circular(modal));
  static final BorderRadius fullBorderRadius = BorderRadius.circular(full);
  static final BorderRadius pillBorderRadius = BorderRadius.circular(pill);

  // Short named aliases
  static BorderRadius get cardRadius => cardBorderRadius;
  static BorderRadius get buttonRadius => buttonBorderRadius;
  static BorderRadius get modalTop => modalTopRadius;
  static BorderRadius get chipRadiusObj => chipBorderRadius;
  static BorderRadius get pillRadius => pillBorderRadius;
}
