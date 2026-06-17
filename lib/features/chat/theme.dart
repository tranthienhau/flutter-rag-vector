import 'package:flutter/material.dart';

/// Obsidian Flux (Light) design tokens, derived from the Stitch design system.
///
/// "Airy Minimalist": crisp white base, optimized indigo primary, layered
/// slate surfaces, soft ambient shadows, and a technical type pairing of
/// Geist (headlines) / Inter (body) / JetBrains Mono (labels & metadata).
class AppColors {
  AppColors._();

  static const surface = Color(0xFFF8F9FF);
  static const background = Color(0xFFF8F9FF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFEFF4FF);
  static const surfaceContainer = Color(0xFFE5EEFF);
  static const surfaceContainerHigh = Color(0xFFDCE9FF);
  static const surfaceContainerHighest = Color(0xFFD3E4FE);

  static const onSurface = Color(0xFF0B1C30);
  static const onBackground = Color(0xFF0B1C30);
  static const onSurfaceVariant = Color(0xFF464555);
  static const outline = Color(0xFF777587);
  static const outlineVariant = Color(0xFFC7C4D8);

  static const primary = Color(0xFF3525CD);
  static const primaryContainer = Color(0xFF4F46E5);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryFixed = Color(0xFFE2DFFF);
  static const onPrimaryFixedVariant = Color(0xFF3323CC);

  static const secondary = Color(0xFF565E74);
  static const secondaryContainer = Color(0xFFDAE2FD);
  static const onSecondaryContainer = Color(0xFF5C647A);
  static const secondaryFixed = Color(0xFFDAE2FD);

  static const tertiary = Color(0xFF46494B);
  static const tertiaryFixed = Color(0xFFE0E3E5);

  static const error = Color(0xFFBA1A1A);
}

/// Ambient elevation shadows from the design system.
const kCardShadow = [
  BoxShadow(
    color: Color(0x0D0F172A), // rgba(15,23,42,0.05)
    blurRadius: 20,
    offset: Offset(0, 4),
  ),
];

const kPopoverShadow = [
  BoxShadow(
    color: Color(0x1A0F172A), // rgba(15,23,42,0.1)
    blurRadius: 30,
    offset: Offset(0, 10),
  ),
];

ThemeData buildAppTheme() {
  final scheme = const ColorScheme.light(
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.secondary,
    error: AppColors.error,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Inter',
    splashFactory: InkSparkle.splashFactory,
  );
}

// Type styles -------------------------------------------------------------

const _geist = 'Geist';
const _mono = 'JetBrains Mono';

const kHeadlineXl = TextStyle(
  fontFamily: _geist,
  fontSize: 32,
  height: 40 / 32,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.6,
  color: AppColors.onBackground,
);

const kHeadlineMd = TextStyle(
  fontFamily: _geist,
  fontSize: 22,
  height: 30 / 22,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.2,
  color: AppColors.onSurface,
);

const kHeadlineSm = TextStyle(
  fontFamily: _geist,
  fontSize: 18,
  height: 24 / 18,
  fontWeight: FontWeight.w700,
  color: AppColors.onSurface,
);

const kBodyLg = TextStyle(
  fontFamily: 'Inter',
  fontSize: 17,
  height: 26 / 17,
  fontWeight: FontWeight.w400,
  color: AppColors.onSurfaceVariant,
);

const kBodyMd = TextStyle(
  fontFamily: 'Inter',
  fontSize: 15.5,
  height: 24 / 15.5,
  fontWeight: FontWeight.w400,
  color: AppColors.onSurface,
);

const kBodySm = TextStyle(
  fontFamily: 'Inter',
  fontSize: 13.5,
  height: 19 / 13.5,
  fontWeight: FontWeight.w400,
  color: AppColors.onSurfaceVariant,
);

const kLabelMd = TextStyle(
  fontFamily: _mono,
  fontSize: 13,
  height: 18 / 13,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.3,
  color: AppColors.onSurface,
);

const kLabelSm = TextStyle(
  fontFamily: _mono,
  fontSize: 11,
  height: 16 / 11,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.8,
  color: AppColors.outline,
);
