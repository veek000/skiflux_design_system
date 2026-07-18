import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Figma component set: **Controls** (`190:6923`) — Chips: Pill
///
/// Variants:
/// - `Chips: Pill - Default` → fill `Content/Secondary Inverse`, label `Content/Secondary`
/// - `Chips: Pill - Clicked` → fill `Content/Brand`, label `Content/Primary Inverse`
///
/// Text style: `UI Style/Badge - Tag Medium`
/// Radius: `Radius/Pill`
/// Padding: Default V/H = 8/16 (`Space/S` / `Space/L`); height 30
class SkifluxChip extends StatelessWidget {
  const SkifluxChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.trailing,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? SkifluxColors.contentBrand
        : SkifluxColors.contentSecondaryInverse;
    final fg = selected
        ? SkifluxColors.contentPrimaryInverse
        : SkifluxColors.contentSecondary;

    return Material(
      color: bg,
      borderRadius: SkifluxRadii.borderPill,
      child: InkWell(
        onTap: onSelected == null ? null : () => onSelected!(!selected),
        borderRadius: SkifluxRadii.borderPill,
        child: Padding(
          padding: EdgeInsets.only(
            top: SkifluxSpacing.spaceS,
            bottom: SkifluxSpacing.spaceS,
            left: SkifluxSpacing.spaceL,
            right: selected && trailing != null
                ? SkifluxSpacing.spaceS
                : SkifluxSpacing.spaceL,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: SkifluxTypography.uiBadgeTagMedium.copyWith(color: fg),
              ),
              if (trailing != null) ...[
                const SizedBox(width: SkifluxSpacing.spaceS),
                IconTheme(
                  data: IconThemeData(color: fg, size: SkifluxSpacing.spaceL),
                  child: trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
