import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Figma component set: **Text Fields** (`146:26788`)
///
/// States: Default | Focused | Filled | Error | Disabled
///
/// Token bindings (Default):
/// - fill → `Background/Primary`
/// - stroke → `Border/Secondary` width 1 (`Width/XS`)
/// - radius → `Radius/Pill`
/// - padding → V `Space/M` (12), H `Space/L` (16)
/// - placeholder → text style `UI Style/Placeholder Text` + `Content/Tertiary`
///
/// Focused: stroke `Border/Focus` width 2 (`Width/M`)
/// Error: stroke `Content/Negative` width 2
/// Disabled: fill `Background/Disabled`
enum SkifluxInputState { defaultState, focused, filled, error, disabled }

class SkifluxInputField extends StatelessWidget {
  const SkifluxInputField({
    super.key,
    this.controller,
    this.hintText = 'Input text',
    this.label,
    this.caption,
    this.state,
    this.enabled = true,
    this.hasError = false,
    this.leadingIcon,
    this.trailingIcon,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType,
    this.fieldKey,
  });

  final TextEditingController? controller;
  final String hintText;
  final String? label;
  final String? caption;

  /// Explicit state override; otherwise derived from focus / error / enabled.
  final SkifluxInputState? state;
  final bool enabled;
  final bool hasError;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType? keyboardType;

  /// Optional [Key] forwarded to the inner [TextField] widget.
  /// Used by tests to reliably find the input via [find.byKey].
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          // Figma: Input label component + text style UI Style/Input Label
          Text(
            label!,
            style: SkifluxTypography.uiInputLabel.copyWith(
              color: enabled
                  ? SkifluxColors.contentPrimary
                  : SkifluxColors.contentDisabled,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceXs),
        ],
        TextField(
          key: fieldKey,
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: SkifluxTypography.bodyP10Regular.copyWith(
            color: SkifluxColors.contentSecondary,
          ),
          cursorColor: SkifluxColors.borderFocus,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: SkifluxTypography.uiPlaceholderText.copyWith(
              color: SkifluxColors.contentTertiary,
            ),
            filled: true,
            fillColor: enabled
                ? SkifluxColors.backgroundPrimary
                : SkifluxColors.backgroundDisabled,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: SkifluxSpacing.spaceL,
              vertical: SkifluxSpacing.spaceM,
            ),
            prefixIcon: leadingIcon != null
                ? IconTheme(
                    data: const IconThemeData(
                      color: SkifluxColors.contentTertiary,
                      size: SkifluxSpacing.spaceL,
                    ),
                    child: leadingIcon!,
                  )
                : null,
            suffixIcon: trailingIcon != null
                ? IconTheme(
                    data: const IconThemeData(
                      color: SkifluxColors.contentTertiary,
                      size: SkifluxSpacing.spaceL,
                    ),
                    child: trailingIcon!,
                  )
                : null,
            border: _border(
              SkifluxColors.borderSecondary,
              SkifluxBorderWidth.xs,
            ),
            enabledBorder: _border(
              SkifluxColors.borderSecondary,
              SkifluxBorderWidth.xs,
            ),
            focusedBorder: _border(
              SkifluxColors.borderFocus,
              SkifluxBorderWidth.m,
            ),
            errorBorder: _border(
              SkifluxColors.contentNegative,
              SkifluxBorderWidth.m,
            ),
            focusedErrorBorder: _border(
              SkifluxColors.contentNegative,
              SkifluxBorderWidth.m,
            ),
            disabledBorder: _border(
              SkifluxColors.borderSecondary,
              SkifluxBorderWidth.s,
            ),
            errorText: hasError ? (caption ?? '') : null,
          ),
        ),
        if (caption != null && !hasError) ...[
          const SizedBox(height: SkifluxSpacing.spaceXs),
          Text(
            caption!,
            style: SkifluxTypography.bodyP10Regular.copyWith(
              color: SkifluxColors.contentTertiary,
            ),
          ),
        ],
      ],
    );
  }

  static OutlineInputBorder _border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: SkifluxRadii.borderPill,
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
