import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Figma pattern: **empty state** (Search flow 07 `304:9489` "What are you
/// looking for?" / Search flow 05 `2374:11925` "Nothing found").
///
/// 98px `Brand/100` circle around a 48px brand-colored icon, `Heading H7
/// Bold` title, `Body p8 Regular` `Content/Tertiary` body — all centered,
/// wrapped in 48px (`Space/4XL`) vertical padding.
///
/// [icon] takes any widget so callers can pass an [Icon] (Remix glyph) or an
/// [Image] for glyphs missing from the icon font (e.g. Figma's
/// `search-x-fill`, bundled as
/// `packages/skiflux_design_system/assets/images/search_x_fill.png`).
class SkifluxEmptyState extends StatelessWidget {
  const SkifluxEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  }) : _compact = false;

  /// The same state at the scale a rail or card can hold.
  ///
  /// The full size assumes a screen to itself: 98px circle plus 48px of
  /// vertical padding is taller than a horizontal rail, so an empty rail
  /// either clipped the state or forced the rail to grow. Same content, half
  /// the furniture — use [iconSizeCompact] for the icon passed in.
  const SkifluxEmptyState.compact({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  }) : _compact = true;

  final Widget icon;
  final String title;
  final String message;

  final bool _compact;

  /// Circle diameter from Figma (`304:9491`).
  static const double _circleSize = 98;
  static const double _circleSizeCompact = 64;

  /// Icon box inside the circle.
  static const double iconSize = 48;
  static const double iconSizeCompact = 32;

  @override
  Widget build(BuildContext context) {
    final circle = _compact ? _circleSizeCompact : _circleSize;
    final glyph = _compact ? iconSizeCompact : iconSize;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: _compact ? SkifluxSpacing.spaceM : SkifluxSpacing.space4xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: circle,
            height: circle,
            decoration: const BoxDecoration(
              color: SkifluxColors.brand100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(width: glyph, height: glyph, child: icon),
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceS),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SkifluxSpacing.spaceL,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style:
                      (_compact
                              ? SkifluxTypography.headingH9Bold
                              : SkifluxTypography.headingH7Bold)
                          .copyWith(color: SkifluxColors.contentPrimary),
                ),
                const SizedBox(height: SkifluxSpacing.spaceXs),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style:
                      (_compact
                              ? SkifluxTypography.bodyP11Regular
                              : SkifluxTypography.bodyP8Regular)
                          .copyWith(color: SkifluxColors.contentTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
