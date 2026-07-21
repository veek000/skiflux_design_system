import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/skiflux_sheet.dart';
import 'data/subscriptions_store.dart';

/// Filter sheet for the "Latest from Creators" feed. Options per spec:
/// Recent (by post recency) · Today · Continue watching · Unwatched.
Future<SubscriptionFeedFilter?> showSubscriptionFilterSheet(
  BuildContext context, {
  required SubscriptionFeedFilter current,
}) {
  return showSkifluxSheet<SubscriptionFeedFilter>(
    context: context,
    builder: (context) => SkifluxSheetShell(
      title: 'Filter episodes',
      child: ListView(
        shrinkWrap: true,
        // Sheet drags down only when the list is at its top.
        controller: ModalScrollController.of(context),
        padding: const EdgeInsets.symmetric(
          horizontal: SkifluxSpacing.spaceL,
          vertical: SkifluxSpacing.spaceS,
        ),
        children: [
          for (final option in SubscriptionFeedFilter.values)
            _FilterOptionRow(
              option: option,
              selected: option == current,
              onTap: () => Navigator.of(context).pop(option),
            ),
        ],
      ),
    ),
  );
}

/// Sort sheet for the All Subscriptions "Filter" link. Options per spec:
/// Most relevant · New activity · A–Z.
Future<SubscriptionListSort?> showSubscriptionSortSheet(
  BuildContext context, {
  required SubscriptionListSort current,
}) {
  return showSkifluxSheet<SubscriptionListSort>(
    context: context,
    builder: (context) => SkifluxSheetShell(
      title: 'Filter',
      child: ListView(
        shrinkWrap: true,
        // Sheet drags down only when the list is at its top.
        controller: ModalScrollController.of(context),
        padding: const EdgeInsets.symmetric(
          horizontal: SkifluxSpacing.spaceL,
          vertical: SkifluxSpacing.spaceS,
        ),
        children: [
          for (final option in SubscriptionListSort.values)
            _SheetOptionRow(
              icon: switch (option) {
                SubscriptionListSort.mostRelevant => RemixIcons.sparkling_fill,
                SubscriptionListSort.newActivity => RemixIcons.pulse_line,
                SubscriptionListSort.aToZ => RemixIcons.sort_alphabet_asc,
              },
              label: option.label,
              selected: option == current,
              onTap: () => Navigator.of(context).pop(option),
            ),
        ],
      ),
    ),
  );
}

/// Result of the bell dropdown: either a new notification level or
/// unsubscribe.
sealed class BellAction {
  const BellAction();
}

class SetNotificationMode extends BellAction {
  const SetNotificationMode(this.mode);
  final CreatorNotificationMode mode;
}

class Unsubscribe extends BellAction {
  const Unsubscribe();
}

/// Bell-pill dropdown for a subscribed creator. Options per spec:
/// All · Personalized · None · Unsubscribe.
Future<BellAction?> showBellSheet(
  BuildContext context, {
  required SubscribedCreator creator,
}) {
  return showSkifluxSheet<BellAction>(
    context: context,
    builder: (context) => SkifluxSheetShell(
      title: creator.name,
      child: ListView(
        shrinkWrap: true,
        // Sheet drags down only when the list is at its top.
        controller: ModalScrollController.of(context),
        padding: const EdgeInsets.symmetric(
          horizontal: SkifluxSpacing.spaceL,
          vertical: SkifluxSpacing.spaceS,
        ),
        children: [
          for (final mode in CreatorNotificationMode.values)
            _SheetOptionRow(
              icon: switch (mode) {
                CreatorNotificationMode.all => RemixIcons.notification_fill,
                CreatorNotificationMode.personalized =>
                  RemixIcons.notification_line,
                CreatorNotificationMode.none => RemixIcons.notification_off_line,
              },
              label: mode.label,
              selected: mode == creator.notificationMode,
              onTap: () =>
                  Navigator.of(context).pop(SetNotificationMode(mode)),
            ),
          _SheetOptionRow(
            icon: RemixIcons.user_unfollow_line,
            label: 'Unsubscribe',
            destructive: true,
            onTap: () => Navigator.of(context).pop(const Unsubscribe()),
          ),
        ],
      ),
    ),
  );
}

/// Generic sheet row: leading icon, label, trailing check when selected.
class _SheetOptionRow extends StatelessWidget {
  const _SheetOptionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final Color color = destructive
        ? SkifluxColors.contentNegative
        : selected
            ? SkifluxColors.contentBrand
            : SkifluxColors.contentPrimary;
    return InkWell(
      borderRadius: SkifluxRadii.borderL,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: SkifluxSpacing.spaceM,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: SkifluxIcons.sizeM,
              color: destructive
                  ? SkifluxColors.contentNegative
                  : selected
                      ? SkifluxColors.contentBrand
                      : SkifluxColors.contentSecondary,
            ),
            const SizedBox(width: SkifluxSpacing.spaceM),
            Expanded(
              child: Text(
                label,
                style: SkifluxTypography.headingH10Bold.copyWith(color: color),
              ),
            ),
            if (selected)
              const Icon(
                RemixIcons.check_line,
                size: SkifluxIcons.sizeM,
                color: SkifluxColors.contentBrand,
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterOptionRow extends StatelessWidget {
  const _FilterOptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionFeedFilter option;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (option) {
        SubscriptionFeedFilter.recent => RemixIcons.time_fill,
        SubscriptionFeedFilter.today => RemixIcons.calendar_fill,
        SubscriptionFeedFilter.continueWatching => RemixIcons.play_circle_fill,
        SubscriptionFeedFilter.unwatched => RemixIcons.eye_off_fill,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: SkifluxRadii.borderL,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: SkifluxSpacing.spaceM,
        ),
        child: Row(
          children: [
            Icon(
              _icon,
              size: SkifluxIcons.sizeM,
              color: selected
                  ? SkifluxColors.contentBrand
                  : SkifluxColors.contentSecondary,
            ),
            const SizedBox(width: SkifluxSpacing.spaceM),
            Expanded(
              child: Text(
                option.label,
                style: SkifluxTypography.headingH10Bold.copyWith(
                  color: selected
                      ? SkifluxColors.contentBrand
                      : SkifluxColors.contentPrimary,
                ),
              ),
            ),
            if (selected)
              const Icon(
                RemixIcons.check_line,
                size: SkifluxIcons.sizeM,
                color: SkifluxColors.contentBrand,
              ),
          ],
        ),
      ),
    );
  }
}
