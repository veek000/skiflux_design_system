import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Figma component set: **Button** (`146:26414`)
///
/// Variants:
/// - Size: L | S
/// - Type: Primary | Secondary | Tertiary | Tertiary Mono
/// - State: Default | Hover | Pressed | Disabled
/// - Leading: True | False (icon slot visibility)
///
/// Token bindings (Default Primary L):
/// - fill → `Background/Brand`
/// - label → `Content/Primary Inverse` + text style `UI Style/Button - Large`
/// - radius → `Radius/Pill`
/// - padding L → 12 (`Space/M`) all sides; S → 4/8 (`Space/XS` / `Space/S`)
enum SkifluxButtonSize { l, s }

enum SkifluxButtonType { primary, secondary, tertiary, tertiaryMono, negative }

enum SkifluxButtonState { defaultState, hover, pressed, disabled }

class SkifluxButton extends StatelessWidget {
  const SkifluxButton({
    super.key,
    required this.label,
    this.onPressed,
    this.size = SkifluxButtonSize.l,
    this.type = SkifluxButtonType.primary,
    this.state,
    this.leadingIcon,
    this.trailingIcon,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final SkifluxButtonSize size;
  final SkifluxButtonType type;

  /// When null, derived from [onPressed] (null → disabled).
  final SkifluxButtonState? state;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final bool expanded;

  SkifluxButtonState get _resolvedState {
    if (state != null) return state!;
    if (onPressed == null) return SkifluxButtonState.disabled;
    return SkifluxButtonState.defaultState;
  }

  @override
  Widget build(BuildContext context) {
    final s = _resolvedState;
    final colors = _colorsFor(type, s);
    final isDisabled = s == SkifluxButtonState.disabled;
    final padding = size == SkifluxButtonSize.l
        ? const EdgeInsets.all(SkifluxSpacing.spaceM)
        : const EdgeInsets.symmetric(
            vertical: SkifluxSpacing.spaceXs,
            horizontal: SkifluxSpacing.spaceS,
          );
    final textStyle = size == SkifluxButtonSize.l
        ? SkifluxTypography.uiButtonLarge
        : SkifluxTypography.uiButtonSmall;
    final minHeight =
        size == SkifluxButtonSize.l ? SkifluxUnit.u48 : SkifluxUnit.u32;

    return Material(
      color: colors.background ?? Colors.transparent,
      borderRadius: SkifluxRadii.borderPill,
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        onHover: null,
        borderRadius: SkifluxRadii.borderPill,
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: SkifluxRadii.borderPill,
            border: colors.borderColor != null
                ? Border.all(
                    color: colors.borderColor!,
                    width: SkifluxBorderWidth.xs,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingIcon != null) ...[
                IconTheme(
                  data: IconThemeData(
                    color: colors.foreground,
                    size: SkifluxSpacing.spaceL,
                  ),
                  child: leadingIcon!,
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SkifluxSpacing.spaceXs,
                ),
                child: Text(
                  label,
                  style: textStyle.copyWith(color: colors.foreground),
                ),
              ),
              if (trailingIcon != null) ...[
                IconTheme(
                  data: IconThemeData(
                    color: colors.foreground,
                    size: SkifluxSpacing.spaceL,
                  ),
                  child: trailingIcon!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static _ButtonColors _colorsFor(
    SkifluxButtonType type,
    SkifluxButtonState state,
  ) {
    // Token map from Figma Button component set (Leading=True variants).
    switch (type) {
      case SkifluxButtonType.primary:
        switch (state) {
          case SkifluxButtonState.defaultState:
            return const _ButtonColors(
              background: SkifluxColors.backgroundBrand,
              foreground: SkifluxColors.contentPrimaryInverse,
            );
          case SkifluxButtonState.hover:
            return const _ButtonColors(
              background: SkifluxColors.backgroundBrandHover,
              foreground: SkifluxColors.contentPrimaryInverse,
            );
          case SkifluxButtonState.pressed:
            return const _ButtonColors(
              background: SkifluxColors.backgroundBrandPressed,
              foreground: SkifluxColors.contentPrimaryInverse,
            );
          case SkifluxButtonState.disabled:
            return const _ButtonColors(
              background: SkifluxColors.backgroundBrandDisabled,
              foreground: SkifluxColors.contentPrimaryInverse,
            );
        }
      case SkifluxButtonType.secondary:
        switch (state) {
          case SkifluxButtonState.defaultState:
            // Text fill bound to Content/Primary (remote alias); stroke Border/Tertiary
            return const _ButtonColors(
              foreground: SkifluxColors.contentPrimary,
              borderColor: SkifluxColors.borderTertiary,
            );
          case SkifluxButtonState.hover:
            return const _ButtonColors(
              foreground: SkifluxColors.contentPrimary,
              borderColor: SkifluxColors.borderSecondary,
            );
          case SkifluxButtonState.pressed:
            return const _ButtonColors(
              foreground: SkifluxColors.contentPrimary,
              borderColor: SkifluxColors.borderPrimary,
            );
          case SkifluxButtonState.disabled:
            return const _ButtonColors(
              foreground: SkifluxColors.contentDisabled,
              borderColor: SkifluxColors.borderDisabled,
            );
        }
      case SkifluxButtonType.tertiary:
        switch (state) {
          case SkifluxButtonState.defaultState:
            return const _ButtonColors(
              background: SkifluxColors.contentPrimaryInverse,
              foreground: SkifluxColors.contentBrand,
            );
          case SkifluxButtonState.hover:
            return const _ButtonColors(
              background: SkifluxColors.backgroundHover,
              foreground: SkifluxColors.contentLinkHover,
            );
          case SkifluxButtonState.pressed:
            return const _ButtonColors(
              background: SkifluxColors.backgroundPressed,
              foreground: SkifluxColors.contentLinkPressed,
            );
          case SkifluxButtonState.disabled:
            return const _ButtonColors(
              background: SkifluxColors.backgroundHover,
              foreground: SkifluxColors.contentDisabled,
            );
        }
      case SkifluxButtonType.tertiaryMono:
        switch (state) {
          case SkifluxButtonState.defaultState:
            return const _ButtonColors(
              background: SkifluxColors.contentPrimaryInverse,
              foreground: SkifluxColors.contentPrimary,
            );
          case SkifluxButtonState.hover:
            return const _ButtonColors(
              background: SkifluxColors.backgroundHover,
              foreground: SkifluxColors.contentPrimary,
            );
          case SkifluxButtonState.pressed:
            return const _ButtonColors(
              background: SkifluxColors.backgroundPressed,
              foreground: SkifluxColors.contentPrimary,
            );
          case SkifluxButtonState.disabled:
            return const _ButtonColors(
              background: SkifluxColors.backgroundHover,
              foreground: SkifluxColors.contentDisabled,
            );
        }
      case SkifluxButtonType.negative:
        // Destructive primary — fill `Background/Negative`, label inverse.
        // Used by the insufficient-coins "Buy Coins" CTA (`1256:27566`).
        switch (state) {
          case SkifluxButtonState.defaultState:
            return const _ButtonColors(
              background: SkifluxColors.backgroundNegative,
              foreground: SkifluxColors.contentPrimaryInverse,
            );
          case SkifluxButtonState.hover:
            return const _ButtonColors(
              background: SkifluxColors.contentNegativeBold,
              foreground: SkifluxColors.contentPrimaryInverse,
            );
          case SkifluxButtonState.pressed:
            return const _ButtonColors(
              background: SkifluxColors.red700,
              foreground: SkifluxColors.contentPrimaryInverse,
            );
          case SkifluxButtonState.disabled:
            return const _ButtonColors(
              background: SkifluxColors.red200,
              foreground: SkifluxColors.contentPrimaryInverse,
            );
        }
    }
  }
}

class _ButtonColors {
  const _ButtonColors({
    this.background,
    required this.foreground,
    this.borderColor,
  });

  final Color? background;
  final Color foreground;
  final Color? borderColor;
}
