import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import 'colors.dart';
import 'spacing.dart';

/// Remix Icon system for Skiflux.
///
/// Figma Design System page includes the full **Remix Icons** component library
/// (line + fill). Production icons must use Remix, not Material Icons.
///
/// - Official set: https://github.com/Remix-Design/RemixIcon
/// - Flutter package: `remixicon` → [RemixIcons] / [Remix]
/// - Naming: `{name}_line` (outline) / `{name}_fill` (solid), matching
///   Figma layers like `remix-icons/fill/system/add-fill`.
///
/// Default size in Figma UI chrome is often 16 (`Space/L`) or 24 (`Space/XL`).
abstract final class SkifluxIcons {
  /// Default UI icon size — Figma 16px (`Space/L`).
  static const double sizeS = SkifluxSpacing.spaceL;

  /// Standard icon size — Figma 24px (`Space/XL`), Remix 24×24 grid.
  static const double sizeM = SkifluxSpacing.spaceXl;

  /// Large control icon — Figma 32px (`Space/2XL`).
  static const double sizeL = SkifluxSpacing.space2xl;

  // ── Icons used by design-system components / Figma samples ─────────

  /// Figma: `remix-icons/fill/system/add-fill` (Button leading default)
  static const IconData addFill = RemixIcons.add_fill;

  /// Outline add
  static const IconData addLine = RemixIcons.add_line;

  /// Check (radio active mark, success)
  static const IconData checkFill = RemixIcons.check_fill;
  static const IconData checkLine = RemixIcons.check_line;

  /// User / avatar
  static const IconData userFill = RemixIcons.user_fill;
  static const IconData userLine = RemixIcons.user_line;

  /// Search
  static const IconData searchLine = RemixIcons.search_line;
  static const IconData searchFill = RemixIcons.search_fill;

  /// Close
  static const IconData closeLine = RemixIcons.close_line;
  static const IconData closeFill = RemixIcons.close_fill;

  /// Arrow / nav
  static const IconData arrowLeftLine = RemixIcons.arrow_left_line;
  static const IconData arrowRightLine = RemixIcons.arrow_right_line;
  static const IconData arrowDownLine = RemixIcons.arrow_down_s_line;

  /// Sparkle / 4-point motif family (Figma: sparkling-2-fill)
  static const IconData sparkleFill = RemixIcons.sparkling_2_fill;
  static const IconData sparkleLine = RemixIcons.sparkling_2_line;

  /// Megaphone (Figma: megaphone-fill)
  static const IconData megaphoneFill = RemixIcons.megaphone_fill;
  static const IconData megaphoneLine = RemixIcons.megaphone_line;

  /// Builds a Remix [Icon] with Skiflux defaults.
  ///
  /// ```dart
  /// SkifluxIcons.icon(RemixIcons.home_3_line)
  /// SkifluxIcons.icon(SkifluxIcons.searchLine, size: SkifluxIcons.sizeS)
  /// ```
  static Widget icon(
    IconData data, {
    double size = sizeM,
    Color? color,
    Key? key,
  }) {
    return Icon(
      data,
      key: key,
      size: size,
      color: color ?? SkifluxColors.contentPrimary,
    );
  }
}

/// Thin wrapper so callers can write `SkifluxIcon(RemixIcons.home_3_line)`.
class SkifluxIcon extends StatelessWidget {
  const SkifluxIcon(
    this.icon, {
    super.key,
    this.size = SkifluxIcons.sizeM,
    this.color,
  });

  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color ?? IconTheme.of(context).color ?? SkifluxColors.contentPrimary,
    );
  }
}
