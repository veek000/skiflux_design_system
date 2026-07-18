import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import 'badge.dart';

/// Figma component set: **Mobile Icon Tab** (`62:1652`)
///
/// Variants: Default | Active
/// Optional notification badge (boolean prop in Figma).
///
/// Active icon/label → `Content/Brand`
/// Default icon/label → `Content/Disabled`
class SkifluxMobileTabItem {
  const SkifluxMobileTabItem({
    required this.label,
    required this.icon,
    this.activeIcon,
    this.showBadge = false,
    this.badgeCount,
  });

  final String label;
  final Widget icon;
  final Widget? activeIcon;
  final bool showBadge;
  final int? badgeCount;
}

class SkifluxMobileTabBar extends StatelessWidget {
  const SkifluxMobileTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    this.onTap,
  });

  final List<SkifluxMobileTabItem> items;
  final int currentIndex;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SkifluxColors.backgroundPrimary,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: SkifluxUnit.u56,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _Tab(
                    item: items[i],
                    active: i == currentIndex,
                    onTap: onTap == null ? null : () => onTap!(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.item,
    required this.active,
    this.onTap,
  });

  final SkifluxMobileTabItem item;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Figma Bottom Navigation (848:41140): inactive icon/label use
    // Content/Disabled (#B2B2B2), not Content/Tertiary.
    final color =
        active ? SkifluxColors.contentBrand : SkifluxColors.contentDisabled;
    final icon = active && item.activeIcon != null ? item.activeIcon! : item.icon;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconTheme(
                data: IconThemeData(color: color, size: SkifluxSpacing.spaceXl),
                child: icon,
              ),
              if (item.showBadge)
                Positioned(
                  right: -SkifluxSpacing.spaceXs,
                  top: -SkifluxSpacing.space2xs,
                  child: SkifluxNotificationBadge(
                    type: item.badgeCount == null
                        ? SkifluxBadgeType.indicator
                        : SkifluxBadgeType.number,
                    count: item.badgeCount,
                  ),
                ),
            ],
          ),
          const SizedBox(height: SkifluxSpacing.space2xs),
          Text(
            item.label,
            // Figma home nav labels: 12/16 — text style `UI Style/Input Content`.
            style: SkifluxTypography.uiInputContent.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
