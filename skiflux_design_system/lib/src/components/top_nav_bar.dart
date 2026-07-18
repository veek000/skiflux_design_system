import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Figma component sets:
/// - **Top Navigation Bar 1** (`62:1689`) — left + right icons
/// - **Top Navigation Bar 2** (`62:1708`) — right icon / text / button
///
/// Variants: Default | Text Right | Button Right
/// Label text style: `UI Style/Nav Item` (Creato Display Medium 14)
/// Background: `Background/Primary` (Light status headers)
class SkifluxTopNavBar extends StatelessWidget implements PreferredSizeWidget {
  const SkifluxTopNavBar({
    super.key,
    this.label,
    this.showLabel = true,
    this.labelStyle,
    this.leading,
    this.trailing,
    this.trailingText,
    this.onTrailingTextTap,
    this.backgroundColor,
  });

  final String? label;
  final bool showLabel;

  /// Overrides the default `UI Style/Nav Item` label style. Screen-level
  /// nav bars in Figma (e.g. Profile) use `Heading Style/Heading H8 Bold`.
  final TextStyle? labelStyle;

  final Widget? leading;
  final Widget? trailing;
  final String? trailingText;
  final VoidCallback? onTrailingTextTap;
  final Color? backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(SkifluxUnit.u56);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? SkifluxColors.backgroundPrimary,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: SkifluxUnit.u56,
          padding: const EdgeInsets.symmetric(horizontal: SkifluxSpacing.spaceL),
          child: Row(
            children: [
              if (leading != null)
                IconTheme(
                  data: const IconThemeData(
                    color: SkifluxColors.contentPrimary,
                    size: SkifluxSpacing.spaceXl,
                  ),
                  child: leading!,
                ),
              if (showLabel && label != null)
                Expanded(
                  child: Text(
                    label!,
                    textAlign: TextAlign.center,
                    style: (labelStyle ?? SkifluxTypography.uiNavItem)
                        .copyWith(color: SkifluxColors.contentPrimary),
                  ),
                )
              else
                const Spacer(),
              if (trailingText != null)
                GestureDetector(
                  onTap: onTrailingTextTap,
                  child: Text(
                    trailingText!,
                    style: SkifluxTypography.uiNavItem.copyWith(
                      color: SkifluxColors.contentBrand,
                    ),
                  ),
                )
              else if (trailing != null)
                IconTheme(
                  data: const IconThemeData(
                    color: SkifluxColors.contentPrimary,
                    size: SkifluxSpacing.spaceXl,
                  ),
                  child: trailing!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
