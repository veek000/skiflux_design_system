import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Assembles [ThemeData] from Figma-sourced tokens.
/// Light mode only — Semantic Color collection has a single mode: **Light**.
abstract final class SkifluxAppTheme {
  static ThemeData get light {
    final scheme = SkifluxColors.lightColorScheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: SkifluxColors.backgroundPrimary,
      textTheme: SkifluxTypography.textTheme.apply(
        bodyColor: SkifluxColors.contentPrimary,
        displayColor: SkifluxColors.contentPrimary,
      ),
      primaryTextTheme: SkifluxTypography.textTheme.apply(
        bodyColor: SkifluxColors.contentPrimaryInverse,
        displayColor: SkifluxColors.contentPrimaryInverse,
      ),
      fontFamily: SkifluxFontFamily.dmSans,
      dividerColor: SkifluxColors.borderTertiary,
      disabledColor: SkifluxColors.contentDisabled,
      appBarTheme: const AppBarTheme(
        backgroundColor: SkifluxColors.backgroundPrimary,
        foregroundColor: SkifluxColors.contentPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: SkifluxTypography.headingH8Bold,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SkifluxColors.backgroundBrand,
          foregroundColor: SkifluxColors.contentPrimaryInverse,
          disabledBackgroundColor: SkifluxColors.backgroundBrandDisabled,
          disabledForegroundColor: SkifluxColors.contentPrimaryInverse,
          textStyle: SkifluxTypography.uiButtonLarge,
          minimumSize: const Size(0, SkifluxUnit.u48),
          padding: const EdgeInsets.all(SkifluxSpacing.spaceM),
          shape: RoundedRectangleBorder(
            borderRadius: SkifluxRadii.borderPill,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SkifluxColors.contentPrimary,
          disabledForegroundColor: SkifluxColors.contentDisabled,
          textStyle: SkifluxTypography.uiButtonLarge,
          minimumSize: const Size(0, SkifluxUnit.u48),
          padding: const EdgeInsets.all(SkifluxSpacing.spaceM),
          side: const BorderSide(
            color: SkifluxColors.borderTertiary,
            width: SkifluxBorderWidth.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: SkifluxRadii.borderPill,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SkifluxColors.contentBrand,
          disabledForegroundColor: SkifluxColors.contentDisabled,
          textStyle: SkifluxTypography.uiButtonLarge,
          minimumSize: const Size(0, SkifluxUnit.u48),
          padding: const EdgeInsets.all(SkifluxSpacing.spaceM),
          shape: RoundedRectangleBorder(
            borderRadius: SkifluxRadii.borderPill,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SkifluxColors.backgroundPrimary,
        hintStyle: SkifluxTypography.uiPlaceholderText.copyWith(
          color: SkifluxColors.contentTertiary,
        ),
        labelStyle: SkifluxTypography.uiInputLabel.copyWith(
          color: SkifluxColors.contentPrimary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SkifluxSpacing.spaceL,
          vertical: SkifluxSpacing.spaceM,
        ),
        border: OutlineInputBorder(
          borderRadius: SkifluxRadii.borderPill,
          borderSide: const BorderSide(
            color: SkifluxColors.borderSecondary,
            width: SkifluxBorderWidth.xs,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SkifluxRadii.borderPill,
          borderSide: const BorderSide(
            color: SkifluxColors.borderSecondary,
            width: SkifluxBorderWidth.xs,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SkifluxRadii.borderPill,
          borderSide: const BorderSide(
            color: SkifluxColors.borderFocus,
            width: SkifluxBorderWidth.m,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: SkifluxRadii.borderPill,
          borderSide: const BorderSide(
            color: SkifluxColors.contentNegative,
            width: SkifluxBorderWidth.m,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: SkifluxRadii.borderPill,
          borderSide: const BorderSide(
            color: SkifluxColors.contentNegative,
            width: SkifluxBorderWidth.m,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: SkifluxRadii.borderPill,
          borderSide: const BorderSide(
            color: SkifluxColors.borderSecondary,
            width: SkifluxBorderWidth.s,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: SkifluxColors.contentSecondaryInverse,
        selectedColor: SkifluxColors.contentBrand,
        labelStyle: SkifluxTypography.uiBadgeTagMedium.copyWith(
          color: SkifluxColors.contentSecondary,
        ),
        secondaryLabelStyle: SkifluxTypography.uiBadgeTagMedium.copyWith(
          color: SkifluxColors.contentPrimaryInverse,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: SkifluxSpacing.spaceL,
          vertical: SkifluxSpacing.spaceS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: SkifluxRadii.borderPill,
        ),
        side: BorderSide.none,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return SkifluxColors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return SkifluxColors.backgroundBrand;
          }
          return SkifluxColors.neutral100;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return SkifluxColors.contentBrand;
          }
          return SkifluxColors.borderSecondary;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: SkifluxColors.backgroundBrand,
        circularTrackColor: SkifluxColors.neutral100,
      ),
      // Surface/L* colors are placeholders (white). Elevation = effect styles.
      cardTheme: CardThemeData(
        color: SkifluxColors.surfaceL0,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: SkifluxRadii.borderL,
          side: const BorderSide(
            color: SkifluxColors.borderTertiary,
            width: SkifluxBorderWidth.xs,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SkifluxColors.backgroundPrimary,
        selectedItemColor: SkifluxColors.contentBrand,
        // Figma Bottom Navigation (848:41140): inactive items use
        // Content/Disabled (#B2B2B2).
        unselectedItemColor: SkifluxColors.contentDisabled,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: SkifluxColors.backgroundInverse,
        contentTextStyle: SkifluxTypography.bodyP9Regular.copyWith(
          color: SkifluxColors.contentPrimaryInverse,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: SkifluxRadii.borderM,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
