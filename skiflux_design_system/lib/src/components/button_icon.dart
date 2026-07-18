import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import 'button.dart';

/// Figma component set: **Button Icon** (`146:26631`)
///
/// Same Size / Type / State tokens as [SkifluxButton], icon-only.
/// L: padding 12 (`Space/M`), min 48 (`Unit/48`)
/// S: padding 4/8, min 32 (`Unit/32`)
class SkifluxIconButton extends StatelessWidget {
  const SkifluxIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = SkifluxButtonSize.l,
    this.type = SkifluxButtonType.primary,
    this.state,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final SkifluxButtonSize size;
  final SkifluxButtonType type;
  final SkifluxButtonState? state;

  @override
  Widget build(BuildContext context) {
    // Reuse SkifluxButton color resolution via a thin wrapper.
    return SkifluxButton(
      label: '',
      onPressed: onPressed,
      size: size,
      type: type,
      state: state,
      leadingIcon: icon,
    );
  }
}

/// Compact icon-only control without empty label padding.
class SkifluxIconButtonCompact extends StatelessWidget {
  const SkifluxIconButtonCompact({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = SkifluxButtonSize.l,
    this.type = SkifluxButtonType.primary,
    this.state,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final SkifluxButtonSize size;
  final SkifluxButtonType type;
  final SkifluxButtonState? state;

  SkifluxButtonState get _resolved {
    if (state != null) return state!;
    if (onPressed == null) return SkifluxButtonState.disabled;
    return SkifluxButtonState.defaultState;
  }

  @override
  Widget build(BuildContext context) {
    // Mirror SkifluxButton token map by delegating to a private construction
    // pattern: use TextButton/Elevated based on type with same tokens.
    final s = _resolved;
    final colors = _resolve(type, s);
    final padding = size == SkifluxButtonSize.l
        ? const EdgeInsets.all(SkifluxSpacing.spaceM)
        : const EdgeInsets.all(SkifluxSpacing.spaceXs);
    final dim =
        size == SkifluxButtonSize.l ? SkifluxUnit.u48 : SkifluxUnit.u32;

    return Material(
      color: colors.$1 ?? Colors.transparent,
      borderRadius: SkifluxRadii.borderPill,
      child: InkWell(
        onTap: s == SkifluxButtonState.disabled ? null : onPressed,
        borderRadius: SkifluxRadii.borderPill,
        child: Container(
          width: dim,
          height: dim,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: SkifluxRadii.borderPill,
            border: colors.$3 != null
                ? Border.all(color: colors.$3!, width: SkifluxBorderWidth.xs)
                : null,
          ),
          child: IconTheme(
            data: IconThemeData(
              color: colors.$2,
              size: SkifluxSpacing.spaceL,
            ),
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }

  /// Returns (background, foreground, border).
  static (Color?, Color, Color?) _resolve(
    SkifluxButtonType type,
    SkifluxButtonState state,
  ) {
    // Same token map as SkifluxButton.
    switch (type) {
      case SkifluxButtonType.primary:
        switch (state) {
          case SkifluxButtonState.defaultState:
            return (
              SkifluxColors.backgroundBrand,
              SkifluxColors.contentPrimaryInverse,
              null
            );
          case SkifluxButtonState.hover:
            return (
              SkifluxColors.backgroundBrandHover,
              SkifluxColors.contentPrimaryInverse,
              null
            );
          case SkifluxButtonState.pressed:
            return (
              SkifluxColors.backgroundBrandPressed,
              SkifluxColors.contentPrimaryInverse,
              null
            );
          case SkifluxButtonState.disabled:
            return (
              SkifluxColors.backgroundBrandDisabled,
              SkifluxColors.contentPrimaryInverse,
              null
            );
        }
      case SkifluxButtonType.secondary:
        switch (state) {
          case SkifluxButtonState.defaultState:
            return (
              null,
              SkifluxColors.contentPrimary,
              SkifluxColors.borderTertiary
            );
          case SkifluxButtonState.hover:
            return (
              null,
              SkifluxColors.contentPrimary,
              SkifluxColors.borderSecondary
            );
          case SkifluxButtonState.pressed:
            return (
              null,
              SkifluxColors.contentPrimary,
              SkifluxColors.borderPrimary
            );
          case SkifluxButtonState.disabled:
            return (
              null,
              SkifluxColors.contentDisabled,
              SkifluxColors.borderDisabled
            );
        }
      case SkifluxButtonType.tertiary:
        switch (state) {
          case SkifluxButtonState.defaultState:
            return (
              SkifluxColors.contentPrimaryInverse,
              SkifluxColors.contentBrand,
              null
            );
          case SkifluxButtonState.hover:
            return (
              SkifluxColors.backgroundHover,
              SkifluxColors.contentLinkHover,
              null
            );
          case SkifluxButtonState.pressed:
            return (
              SkifluxColors.backgroundPressed,
              SkifluxColors.contentLinkPressed,
              null
            );
          case SkifluxButtonState.disabled:
            return (
              SkifluxColors.backgroundHover,
              SkifluxColors.contentDisabled,
              null
            );
        }
      case SkifluxButtonType.tertiaryMono:
        switch (state) {
          case SkifluxButtonState.defaultState:
            return (
              SkifluxColors.contentPrimaryInverse,
              SkifluxColors.contentPrimary,
              null
            );
          case SkifluxButtonState.hover:
            return (
              SkifluxColors.backgroundHover,
              SkifluxColors.contentPrimary,
              null
            );
          case SkifluxButtonState.pressed:
            return (
              SkifluxColors.backgroundPressed,
              SkifluxColors.contentPrimary,
              null
            );
          case SkifluxButtonState.disabled:
            return (
              SkifluxColors.backgroundHover,
              SkifluxColors.contentDisabled,
              null
            );
        }
    }
  }
}
