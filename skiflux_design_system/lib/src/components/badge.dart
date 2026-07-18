import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Figma component set: **Notification Badge** (`62:1647`)
///
/// Variants:
/// - Type=Number — 16×16, white label (`Primary/White`)
/// - Type=Indicator — 8×8 dot
///
/// Fill → semantic `Content/Negative` (`#D01111`).
/// Indicator dot carries a `Border/Inverse` (white) ring — Figma renders the
/// 8×8 dot with a 2px white outline so it separates from the icon behind it.
enum SkifluxBadgeType { number, indicator }

class SkifluxNotificationBadge extends StatelessWidget {
  const SkifluxNotificationBadge({
    super.key,
    this.type = SkifluxBadgeType.number,
    this.count,
    this.backgroundColor,
  });

  final SkifluxBadgeType type;
  final int? count;

  /// Optional override. Default: [SkifluxColors.contentNegative].
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? SkifluxColors.contentNegative;

    if (type == SkifluxBadgeType.indicator) {
      // Figma: 8×8 dot with the white ring OUTSIDE the dot (inset -25% =
      // 2px per side). Flutter strokes inside the box, so the box grows to
      // 12×12 to keep the red dot itself at 8×8.
      return Container(
        width: SkifluxSpacing.spaceS + SkifluxBorderWidth.m * 2,
        height: SkifluxSpacing.spaceS + SkifluxBorderWidth.m * 2,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(
            color: SkifluxColors.borderInverse,
            width: SkifluxBorderWidth.m,
          ),
        ),
      );
    }

    final label = count == null ? '' : (count! > 99 ? '99+' : '$count');
    return Container(
      constraints: const BoxConstraints(
        minWidth: SkifluxSpacing.spaceL,
        minHeight: SkifluxSpacing.spaceL,
      ),
      padding: const EdgeInsets.symmetric(horizontal: SkifluxSpacing.space2xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: SkifluxRadii.borderPill,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: SkifluxTypography.uiBadgeTagSmall.copyWith(
          color: SkifluxColors.white,
        ),
      ),
    );
  }
}
