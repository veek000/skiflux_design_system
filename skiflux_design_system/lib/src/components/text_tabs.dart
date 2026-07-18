import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// One entry in a [SkifluxTextTabs] row.
class SkifluxTextTab {
  const SkifluxTextTab({required this.label, this.count});

  final String label;

  /// Optional count badge rendered after the label.
  final int? count;
}

/// Figma pattern: **text tabs with count badges** (Search flow `304:9617`;
/// listed in the Design System as text Tabs, previously unimplemented).
///
/// Equal-width tabs over a 1px `Border/Tertiary` baseline:
/// - Active: `Content/Brand` label (`UI Style/Button - Medium`), 1px
///   `Content/Brand` underline, count pill `Background/Selected` +
///   `Content/Brand`.
/// - Inactive: `Content/Disabled` label, count pill `Background/Hover` +
///   `Content/Disabled`.
///
/// Note: Figma's count badge uses the "Outfit" font — same authoring slip as
/// the ComposeBar placeholder (not in the brand set); DM Sans is used
/// instead.
class SkifluxTextTabs extends StatelessWidget {
  const SkifluxTextTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    this.onSelected,
  });

  final List<SkifluxTextTab> tabs;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: SkifluxColors.borderTertiary,
            width: SkifluxBorderWidth.xs,
          ),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: SkifluxSpacing.spaceS),
            Expanded(child: _tab(tabs[i], selected: i == selectedIndex, index: i)),
          ],
        ],
      ),
    );
  }

  Widget _tab(SkifluxTextTab tab, {required bool selected, required int index}) {
    final contentColor =
        selected ? SkifluxColors.contentBrand : SkifluxColors.contentDisabled;

    return GestureDetector(
      onTap: onSelected == null ? null : () => onSelected!(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: SkifluxSpacing.spaceS),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? SkifluxColors.contentBrand : Colors.transparent,
              width: SkifluxBorderWidth.xs,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              tab.label,
              style: SkifluxTypography.uiButtonMedium.copyWith(
                color: contentColor,
              ),
            ),
            if (tab.count != null) ...[
              const SizedBox(width: SkifluxSpacing.spaceXs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SkifluxSpacing.spaceXs + SkifluxSpacing.space2xs,
                  vertical: SkifluxSpacing.space2xs,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? SkifluxColors.backgroundSelected
                      : SkifluxColors.backgroundHover,
                  borderRadius: SkifluxRadii.borderPill,
                ),
                child: Text(
                  '${tab.count}',
                  style: SkifluxTypography.bodyP11Regular.copyWith(
                    color: contentColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
