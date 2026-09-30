import 'package:flutter/material.dart';

/// Centralized font sizes so text styling isn't scattered as magic numbers.
class AppFontSizes {
  AppFontSizes._();

  static const double f11 = 11;
  static const double f12 = 12;
  static const double f13 = 13;
  static const double f15 = 15;
  static const double f16 = 16;
  static const double f18 = 18;
  static const double f20 = 20;
  static const double f22 = 22;
  static const double f24 = 24;
  static const double f26 = 26;
  static const double f28 = 28;
}

/// Composite text styles reused verbatim across multiple screens.
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle screenTitle = TextStyle(
    fontSize: AppFontSizes.f20,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle cardTitle = TextStyle(
    fontSize: AppFontSizes.f16,
    fontWeight: FontWeight.w700,
  );
}
