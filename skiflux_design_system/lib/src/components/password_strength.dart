import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Levels of the Figma component set **Password strength** (`198:10420`) —
/// one variant per level, each fixing how many of the four bars fill, the
/// fill color, and the caption beneath them.
///
/// Figma mixes the `Background/*` and `Content/*` ramps here: the bars use
/// `Background/Negative` and `Background/Positive` at the extremes but
/// `Content/Notice` / `Content/Info` in the middle. That is reproduced as
/// authored — the hexes are identical either way.
enum SkifluxPasswordStrengthLevel {
  /// Variant "Default" — nothing typed yet; all four bars are empty.
  none(0, SkifluxColors.backgroundHover, 'Password strength',
      SkifluxColors.contentTertiary),

  /// Variant "Password too short" — still no filled bars, only the caption
  /// changes.
  tooShort(0, SkifluxColors.backgroundHover, 'Password too short',
      SkifluxColors.contentTertiary),

  /// Variant "Weak password" — 1 bar, `Background/Negative`.
  weak(1, SkifluxColors.backgroundNegative, 'Weak password',
      SkifluxColors.contentNegative),

  /// Variant "Fair password" — 2 bars, `Content/Notice`.
  fair(2, SkifluxColors.contentNotice, 'Fair password',
      SkifluxColors.contentNotice),

  /// Variant "Good password" — 3 bars, `Content/Info`.
  good(3, SkifluxColors.contentInfo, 'Good password',
      SkifluxColors.contentInfo),

  /// Variant "Strong password" — all 4 bars, `Background/Positive`.
  strong(4, SkifluxColors.backgroundPositive, 'Strong password',
      SkifluxColors.contentPositive);

  const SkifluxPasswordStrengthLevel(
    this.filledBars,
    this.barColor,
    this.caption,
    this.captionColor,
  );

  /// How many of [SkifluxPasswordStrength.barCount] bars are filled.
  final int filledBars;

  /// Fill of the filled bars. Empty bars are always `Background/Hover`.
  final Color barColor;

  /// Figma caption text for the variant.
  final String caption;

  /// Caption color (`Content/*` ramp).
  final Color captionColor;
}

/// Figma component set: **Password strength** (`198:10420`)
///
/// Four 4px meter bars (`Space/XS` tall, `Radius/S`, `Space/S` gaps) over a
/// caption in `UI/Badge-Tag Medium`, laid out as a `Space/S` gap column.
/// Purely presentational — the host screen decides which
/// [SkifluxPasswordStrengthLevel] a password maps to, since the rules differ
/// per flow (sign-up vs. change password).
///
/// ```dart
/// SkifluxPasswordStrength(level: SkifluxPasswordStrengthLevel.fair)
/// ```
class SkifluxPasswordStrength extends StatelessWidget {
  const SkifluxPasswordStrength({
    super.key,
    required this.level,
    this.caption,
  });

  /// Bars in the meter — fixed at 4 by the Figma component.
  static const int barCount = 4;

  final SkifluxPasswordStrengthLevel level;

  /// Overrides the level's built-in Figma caption (e.g. localized copy, or a
  /// specific rule like "Must be at least 8 characters").
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var i = 0; i < barCount; i++) ...[
              if (i > 0) const SizedBox(width: SkifluxSpacing.spaceS),
              Expanded(
                child: Container(
                  height: SkifluxSpacing.spaceXs,
                  decoration: BoxDecoration(
                    color: i < level.filledBars
                        ? level.barColor
                        : SkifluxColors.backgroundHover,
                    borderRadius: SkifluxRadii.borderS,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        Text(
          caption ?? level.caption,
          style: SkifluxTypography.uiBadgeTagMedium.copyWith(
            color: level.captionColor,
          ),
        ),
      ],
    );
  }
}
