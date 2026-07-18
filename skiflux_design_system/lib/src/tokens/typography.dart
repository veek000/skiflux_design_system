import 'package:flutter/material.dart';

/// Font family names from Figma **Primitive Type** variables + local text styles.
///
/// Allowed families only:
/// - Creato Display (Headings, UI Style) — Variable `Font Family/Creato Display`
/// - DM Sans (Body Style, UI Style/Placeholder) — Variable `Font Family/DM Sans`
/// - DM Mono (Code Style) — Variable `Font Family/DM Mono`
///
/// No other families are used in this package.
///
/// The font assets are bundled by THIS package's pubspec, so Flutter registers
/// them under `packages/skiflux_design_system/<family>`. The names below carry
/// that prefix so the styles resolve both inside the package and in any
/// consuming app (e.g. the example) without each app re-declaring the fonts.
abstract final class SkifluxFontFamily {
  static const String _pkg = 'packages/skiflux_design_system/';

  /// Variable: `Font Family/Creato Display`
  static const String creatoDisplay = '${_pkg}Creato Display';

  /// Variable: `Font Family/DM Sans`
  static const String dmSans = '${_pkg}DM Sans';

  /// Variable: `Font Family/DM Mono`
  static const String dmMono = '${_pkg}DM Mono';
}

/// Font weight tokens from Primitive Type.
abstract final class SkifluxFontWeight {
  /// Variable: `Font Weight/regular` = 400
  static const FontWeight regular = FontWeight.w400;

  /// Variable: `Font Weight/medium` = 500
  static const FontWeight medium = FontWeight.w500;

  /// Variable: `Font Weight/semibold` = 600
  static const FontWeight semibold = FontWeight.w600;

  /// Variable: `Font Weight/bold` = 700
  static const FontWeight bold = FontWeight.w700;

  /// Variable: `Font Weight/extrabold` = 800
  static const FontWeight extrabold = FontWeight.w800;
}

/// Text styles matching Figma local text style names exactly.
///
/// Each style is cross-checked against `figma.getLocalTextStylesAsync()` names.
/// Line heights use PERCENT values from Figma (e.g. 120 → height factor 1.2).
abstract final class SkifluxTypography {
  // ── Heading Style (Creato Display) ───────────────────────────────

  /// Text style: `Heading Style/Heading H1`
  /// Creato Display ExtraBold 72 / LH 120% / LS 0
  static const TextStyle headingH1 = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.extrabold,
    fontSize: 72,
    height: 1.2,
    letterSpacing: 0,
  );

  /// Text style: `Heading Style/Heading H2`
  static const TextStyle headingH2 = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.extrabold,
    fontSize: 64,
    height: 1.2,
    letterSpacing: 0,
  );

  /// Text style: `Heading Style/Heading H3`
  static const TextStyle headingH3 = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.extrabold,
    fontSize: 56,
    height: 1.2,
    letterSpacing: 0,
  );

  /// Text style: `Heading Style/Heading H4`
  static const TextStyle headingH4 = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.extrabold,
    fontSize: 40,
    height: 1.2,
    letterSpacing: 0,
  );

  /// Text style: `Heading Style/Heading H5 Bold`
  static const TextStyle headingH5Bold = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.bold,
    fontSize: 36,
    height: 1.2,
    letterSpacing: 0,
  );

  /// Text style: `Heading Style/Heading H5 Extra Bold`
  static const TextStyle headingH5ExtraBold = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.extrabold,
    fontSize: 36,
    height: 1.2,
    letterSpacing: 0,
  );

  /// Text style: `Heading Style/Heading H6 Bold`
  static const TextStyle headingH6Bold = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.bold,
    fontSize: 32,
    height: 1.2,
    letterSpacing: 0,
  );

  /// Text style: `Heading Style/Heading H6 Extra Bold`
  static const TextStyle headingH6ExtraBold = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.extrabold,
    fontSize: 32,
    height: 1.2,
    letterSpacing: 0,
  );

  /// Text style: `Heading Style/Heading H7 Bold`
  static const TextStyle headingH7Bold = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.bold,
    fontSize: 24,
    height: 1.2,
    letterSpacing: 0,
  );

  /// Text style: `Heading Style/Heading H7 Extra bold`
  static const TextStyle headingH7ExtraBold = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.extrabold,
    fontSize: 24,
    height: 1.2,
    letterSpacing: 0,
  );

  /// Text style: `Heading Style/Heading H8 Bold`
  static const TextStyle headingH8Bold = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.bold,
    fontSize: 20,
    height: 1.2,
    letterSpacing: 0,
  );

  /// Text style: `Heading Style/Heading H8 Extra bold`
  static const TextStyle headingH8ExtraBold = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.extrabold,
    fontSize: 20,
    height: 1.2,
    letterSpacing: 0,
  );

  /// Text style: `Heading Style/Heading H9 bold`
  static const TextStyle headingH9Bold = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.bold,
    fontSize: 18,
    height: 1.3,
    letterSpacing: 0,
  );

  /// Text style: `Heading Style/Heading H9 semibold`
  /// Figma style uses Creato Display Medium (weight token medium = 500).
  static const TextStyle headingH9Semibold = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.medium,
    fontSize: 18,
    height: 1.3,
    letterSpacing: 0,
  );

  /// Text style: `Heading Style/Heading H10 bold`
  static const TextStyle headingH10Bold = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.bold,
    fontSize: 16,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Text style: `Heading Style/Heading H10 semibold`
  /// Figma style uses Creato Display Medium.
  static const TextStyle headingH10Semibold = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.medium,
    fontSize: 16,
    height: 1.4,
    letterSpacing: 0,
  );

  // ── Body Style (DM Sans) ─────────────────────────────────────────

  /// Text style: `Body Style/Body - p1`
  static const TextStyle bodyP1 = TextStyle(
    fontFamily: SkifluxFontFamily.dmSans,
    fontWeight: SkifluxFontWeight.regular,
    fontSize: 48,
    height: 1.4,
    letterSpacing: -2,
  );

  /// Text style: `Body Style/Body - p2`
  static const TextStyle bodyP2 = TextStyle(
    fontFamily: SkifluxFontFamily.dmSans,
    fontWeight: SkifluxFontWeight.regular,
    fontSize: 40,
    height: 1.4,
    letterSpacing: -2,
  );

  /// Text style: `Body Style/Body - p3`
  static const TextStyle bodyP3 = TextStyle(
    fontFamily: SkifluxFontFamily.dmSans,
    fontWeight: SkifluxFontWeight.regular,
    fontSize: 36,
    height: 1.4,
    letterSpacing: -2,
  );

  /// Text style: `Body Style/Body - p4`
  static const TextStyle bodyP4 = TextStyle(
    fontFamily: SkifluxFontFamily.dmSans,
    fontWeight: SkifluxFontWeight.regular,
    fontSize: 32,
    height: 1.4,
    letterSpacing: -2,
  );

  /// Text style: `Body Style/Body - p5`
  static const TextStyle bodyP5 = TextStyle(
    fontFamily: SkifluxFontFamily.dmSans,
    fontWeight: SkifluxFontWeight.regular,
    fontSize: 24,
    height: 1.4,
    letterSpacing: -1,
  );

  /// Text style: `Body Style/Body - p6`
  static const TextStyle bodyP6 = TextStyle(
    fontFamily: SkifluxFontFamily.dmSans,
    fontWeight: SkifluxFontWeight.regular,
    fontSize: 20,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Text style: `Body Style/Body - p7 regular`
  static const TextStyle bodyP7Regular = TextStyle(
    fontFamily: SkifluxFontFamily.dmSans,
    fontWeight: SkifluxFontWeight.regular,
    fontSize: 18,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Text style: `Body Style/Body - p7 semibold`
  static const TextStyle bodyP7Semibold = TextStyle(
    fontFamily: SkifluxFontFamily.dmSans,
    fontWeight: SkifluxFontWeight.semibold,
    fontSize: 18,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Text style: `Body Style/Body - p8 regular`
  static const TextStyle bodyP8Regular = TextStyle(
    fontFamily: SkifluxFontFamily.dmSans,
    fontWeight: SkifluxFontWeight.regular,
    fontSize: 16,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Text style: `Body Style/Body - p8 semibold`
  static const TextStyle bodyP8Semibold = TextStyle(
    fontFamily: SkifluxFontFamily.dmSans,
    fontWeight: SkifluxFontWeight.semibold,
    fontSize: 16,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Text style: `Body Style/Body - p9 regular`
  /// paragraphSpacing in Figma: 8
  static const TextStyle bodyP9Regular = TextStyle(
    fontFamily: SkifluxFontFamily.dmSans,
    fontWeight: SkifluxFontWeight.regular,
    fontSize: 14,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Text style: `Body Style/Body - p9 semibold`
  static const TextStyle bodyP9Semibold = TextStyle(
    fontFamily: SkifluxFontFamily.dmSans,
    fontWeight: SkifluxFontWeight.semibold,
    fontSize: 14,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Text style: `Body Style/Body - p10 regular`
  static const TextStyle bodyP10Regular = TextStyle(
    fontFamily: SkifluxFontFamily.dmSans,
    fontWeight: SkifluxFontWeight.regular,
    fontSize: 12,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Text style: `Body Style/Body - p10 semibold`
  static const TextStyle bodyP10Semibold = TextStyle(
    fontFamily: SkifluxFontFamily.dmSans,
    fontWeight: SkifluxFontWeight.semibold,
    fontSize: 12,
    height: 1.5,
    letterSpacing: -0.5,
  );

  /// Text style: `Body Style/Body - p11 regular`
  static const TextStyle bodyP11Regular = TextStyle(
    fontFamily: SkifluxFontFamily.dmSans,
    fontWeight: SkifluxFontWeight.regular,
    fontSize: 10,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Text style: `Body Style/Body - p11 semibold`
  static const TextStyle bodyP11Semibold = TextStyle(
    fontFamily: SkifluxFontFamily.dmSans,
    fontWeight: SkifluxFontWeight.semibold,
    fontSize: 10,
    height: 1.5,
    letterSpacing: 0,
  );

  // ── Code Style (DM Mono) ─────────────────────────────────────────

  /// Text style: `Code Style/Code - Code Inline`
  static const TextStyle codeInline = TextStyle(
    fontFamily: SkifluxFontFamily.dmMono,
    fontWeight: SkifluxFontWeight.regular,
    fontSize: 10,
    height: 1.2,
    letterSpacing: 3,
  );

  /// Text style: `Code Style/Code - Data Label`
  static const TextStyle codeDataLabel = TextStyle(
    fontFamily: SkifluxFontFamily.dmMono,
    fontWeight: SkifluxFontWeight.regular,
    fontSize: 14,
    height: 1.2,
    letterSpacing: 4,
  );

  /// Text style: `Code Style/Code - Question Counter`
  static const TextStyle codeQuestionCounter = TextStyle(
    fontFamily: SkifluxFontFamily.dmMono,
    fontWeight: SkifluxFontWeight.medium,
    fontSize: 16,
    height: 1.2,
    letterSpacing: 6,
  );

  /// Text style: `Code Style/Code - Pass Key`
  static const TextStyle codePassKey = TextStyle(
    fontFamily: SkifluxFontFamily.dmMono,
    fontWeight: SkifluxFontWeight.medium,
    fontSize: 20,
    height: 1.2,
    letterSpacing: 12,
  );

  /// Text style: `Code Style/Code - Score Display`
  static const TextStyle codeScoreDisplay = TextStyle(
    fontFamily: SkifluxFontFamily.dmMono,
    fontWeight: SkifluxFontWeight.medium,
    fontSize: 32,
    height: 1.2,
    letterSpacing: 2,
  );

  /// Text style: `Code Style/Code - Exam Timer`
  /// Figma lineHeight unit PIXELS = 120 (absolute), not percent.
  static const TextStyle codeExamTimer = TextStyle(
    fontFamily: SkifluxFontFamily.dmMono,
    fontWeight: SkifluxFontWeight.medium,
    fontSize: 40,
    height: 120 / 40,
    letterSpacing: 4,
  );

  // ── UI Style ─────────────────────────────────────────────────────

  /// Text style: `UI Style/Placeholder Text`
  /// DM Sans Italic 12 / lineHeight AUTO
  static const TextStyle uiPlaceholderText = TextStyle(
    fontFamily: SkifluxFontFamily.dmSans,
    fontWeight: SkifluxFontWeight.regular,
    fontStyle: FontStyle.italic,
    fontSize: 12,
    letterSpacing: 0,
  );

  /// Text style: `UI Style/Input Label`
  /// Creato Display Bold 16 / lineHeight AUTO
  static const TextStyle uiInputLabel = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.bold,
    fontSize: 16,
    letterSpacing: 0,
  );

  /// Text style: `UI Style/Input Content`
  /// Creato Display Bold 12 / lineHeight PIXELS 16
  static const TextStyle uiInputContent = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.bold,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0,
  );

  /// Text style: `UI Style/Nav Item`
  /// Creato Display Medium 14 / lineHeight AUTO
  static const TextStyle uiNavItem = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.medium,
    fontSize: 14,
    letterSpacing: 0,
  );

  /// Text style: `UI Style/Badge - Tag Small`
  static const TextStyle uiBadgeTagSmall = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.bold,
    fontSize: 10,
    letterSpacing: 0,
  );

  /// Text style: `UI Style/Badge - Tag Medium`
  static const TextStyle uiBadgeTagMedium = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.bold,
    fontSize: 12,
    letterSpacing: 0,
  );

  /// Text style: `UI Style/Button - Small`
  static const TextStyle uiButtonSmall = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.bold,
    fontSize: 12,
    letterSpacing: 0,
  );

  /// Text style: `UI Style/Button - Medium`
  static const TextStyle uiButtonMedium = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.bold,
    fontSize: 14,
    letterSpacing: 0,
  );

  /// Text style: `UI Style/Button - Large`
  static const TextStyle uiButtonLarge = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.bold,
    fontSize: 16,
    letterSpacing: 0,
  );

  /// Text style: `UI Style/Table head 2`
  /// textCase UPPER in Figma
  static const TextStyle uiTableHead2 = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.regular,
    fontSize: 12,
    letterSpacing: 0,
  );

  /// Text style: `UI Style/Table Head 1`
  static const TextStyle uiTableHead1 = TextStyle(
    fontFamily: SkifluxFontFamily.creatoDisplay,
    fontWeight: SkifluxFontWeight.bold,
    fontSize: 12,
    letterSpacing: 0,
  );

  /// Material [TextTheme] mapped from closest Figma styles (Light only).
  static TextTheme get textTheme => const TextTheme(
        displayLarge: headingH1,
        displayMedium: headingH2,
        displaySmall: headingH3,
        headlineLarge: headingH4,
        headlineMedium: headingH5Bold,
        headlineSmall: headingH6Bold,
        titleLarge: headingH7Bold,
        titleMedium: headingH8Bold,
        titleSmall: headingH9Bold,
        bodyLarge: bodyP8Regular,
        bodyMedium: bodyP9Regular,
        bodySmall: bodyP10Regular,
        labelLarge: uiButtonLarge,
        labelMedium: uiButtonMedium,
        labelSmall: uiButtonSmall,
      );
}
