import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Figma component set: **Segment Buttons** (`62:1756`)
///
/// Variants: Default | Active
///
/// Extracted:
/// - radius → `Radius/Pill` (999)
/// - height 28
/// - padding V 6
/// - Active fill `#FFFFFF` → `Primary/White` / `Background/Primary`
/// - Default label `#B2B2B2` → `Content/Disabled` / `Neutral/300`
/// - Active label `#1A1A1A` → `Content/Primary`
///
/// Label uses text style `UI Style/Table Head 1` (Creato Display Bold 12) —
/// matches Task Flow Learning / Mission / Marketplace segments in Figma.
class SkifluxSegmentButton extends StatelessWidget {
  const SkifluxSegmentButton({
    super.key,
    required this.label,
    this.active = false,
    this.onTap,
    this.leadingIcon,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;
  final Widget? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? SkifluxColors.backgroundPrimary : Colors.transparent,
      borderRadius: SkifluxRadii.borderPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: SkifluxRadii.borderPill,
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            // Figma padding V=6 (Unit 6 not in scale; 4+2 = Space/XS + Space/2XS)
            padding: const EdgeInsets.symmetric(
              vertical: SkifluxSpacing.spaceXs + SkifluxSpacing.space2xs,
              horizontal: SkifluxSpacing.spaceL,
            ),
            child: Row(
              // Fill the Expanded slot in [SkifluxSegmentedControl] so each
              // segment is equal-width (Figma Task / Subscriptions tracks).
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leadingIcon != null) ...[
                  IconTheme(
                    data: IconThemeData(
                      color: active
                          ? SkifluxColors.contentPrimary
                          : SkifluxColors.contentDisabled,
                      size: SkifluxSpacing.spaceL,
                    ),
                    child: leadingIcon!,
                  ),
                  const SizedBox(width: SkifluxSpacing.spaceXs),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    // Figma Task Flow segments: UI Style/Table Head 1
                    style: SkifluxTypography.uiTableHead1.copyWith(
                      color: active
                          ? SkifluxColors.contentPrimary
                          : SkifluxColors.contentDisabled,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal group of [SkifluxSegmentButton]s on a muted track.
/// Track fill not fully variable-bound in Figma; uses `Background/Hover`.
class SkifluxSegmentedControl extends StatelessWidget {
  const SkifluxSegmentedControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SkifluxSpacing.space2xs),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundHover,
        borderRadius: SkifluxRadii.borderPill,
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              // Equal-width slots so Learning / Mission / Marketplace
              // (and Link URL / File Upload) fill the track like Figma.
              child: SkifluxSegmentButton(
                label: labels[i],
                active: i == selectedIndex,
                onTap: onChanged == null ? null : () => onChanged!(i),
              ),
            ),
        ],
      ),
    );
  }
}
