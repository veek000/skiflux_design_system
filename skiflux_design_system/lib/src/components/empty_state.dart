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
  });

  final Widget icon;
  final String title;
  final String message;

  /// Circle diameter from Figma (`304:9491`).
  static const double _circleSize = 98;

  /// Icon box inside the circle.
  static const double iconSize = 48;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SkifluxSpacing.space4xl),
      child: Column(
        children: [
          Container(
            width: _circleSize,
            height: _circleSize,
            decoration: const BoxDecoration(
              color: SkifluxColors.brand100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: iconSize,
                height: iconSize,
                child: icon,
              ),
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceS),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SkifluxSpacing.spaceL,
            ),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: SkifluxTypography.headingH7Bold.copyWith(
                    color: SkifluxColors.contentPrimary,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceXs),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: SkifluxTypography.bodyP8Regular.copyWith(
                    color: SkifluxColors.contentTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
