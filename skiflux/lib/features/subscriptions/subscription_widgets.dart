import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/widgets/network_image.dart';
import 'data/subscriptions_store.dart';

// Shared building blocks for the subscriptions flow (Figma section
// `1256:17783`). Screen composites live in subscriptions_screen.dart /
// all_subscriptions_screen.dart.

// ── Stories row (flows 03 & 05) ──────────────────────────────────────

/// "View all" tile — brand100 circle + user icon, "View all" label and
/// "N creators" subtitle beneath.
class ViewAllStoryTile extends StatelessWidget {
  const ViewAllStoryTile({super.key, required this.creatorCount, this.onTap});

  final int creatorCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Transparent ring matches CreatorStoryTile's ring container so
          // all circles in the rail share the same diameter/baseline.
          Container(
            padding: const EdgeInsets.all(SkifluxSpacing.space2xs),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.transparent,
                width: SkifluxBorderWidth.m,
              ),
            ),
            child: Container(
              // Figma: 48px circle, matching the 48px story avatars.
              width: SkifluxUnit.u48,
              height: SkifluxUnit.u48,
              decoration: const BoxDecoration(
                color: SkifluxColors.backgroundSelected,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                RemixIcons.user_fill,
                size: SkifluxIcons.sizeM,
                color: SkifluxColors.contentBrand,
              ),
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceS),
          Text(
            'View all',
            // Figma: UI Style/Input Content (Creato Bold 12).
            style: SkifluxTypography.uiInputContent.copyWith(
              color: SkifluxColors.contentPrimary,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.space2xs),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: SkifluxSpacing.spaceXs,
            ),
            child: Text(
              '$creatorCount creator${creatorCount == 1 ? '' : 's'}',
              // Figma: Creato Bold 10 on content/disabled.
              style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                color: SkifluxColors.contentDisabled,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Creator story avatar with the purple "N new" badge pill and name below.
/// [active] draws the brand ring (flow 03 — creator-filtered view).
class CreatorStoryTile extends ConsumerWidget {
  const CreatorStoryTile({
    super.key,
    required this.creator,
    this.active = false,
    this.onTap,
  });

  final SubscribedCreator creator;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newCount = ref.watch(subscriptionsProvider).newCountFor(creator);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: SkifluxUnit.u64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(SkifluxSpacing.space2xs),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: active
                      ? SkifluxColors.contentBrand
                      : Colors.transparent,
                  width: SkifluxBorderWidth.m,
                ),
              ),
              child: SkifluxAvatar(
                style: SkifluxAvatarStyle.initial,
                // Figma: 48px story avatars.
                size: SkifluxUnit.u48,
                initials: creator.initials,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceS),
            Text(
              creator.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              // Figma: UI Style/Input Content (Creato Bold 12).
              style: SkifluxTypography.uiInputContent.copyWith(
                color: SkifluxColors.contentPrimary,
              ),
            ),
            // Figma: the "N new" pill sits *under* the creator name.
            if (newCount > 0) ...[
              const SizedBox(height: SkifluxSpacing.space2xs),
              _NewBadge(count: newCount),
            ],
          ],
        ),
      ),
    );
  }
}

/// Purple "3 new" pill shown under the creator name.
class _NewBadge extends StatelessWidget {
  const _NewBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Figma: 4px all around plus 4px label inset (8px horizontal total).
      padding: const EdgeInsets.symmetric(
        horizontal: SkifluxSpacing.spaceS,
        vertical: SkifluxSpacing.spaceXs,
      ),
      decoration: BoxDecoration(
        color: SkifluxColors.contentBrand,
        borderRadius: SkifluxRadii.borderPill,
      ),
      child: Text(
        '$count new',
        style: SkifluxTypography.uiBadgeTagSmall.copyWith(
          color: SkifluxColors.contentPrimaryInverse,
        ),
      ),
    );
  }
}

// ── Episode feed card (flows 03 & 05) ────────────────────────────────

/// Feed card: photo thumbnail (EP tag + duration chips) beside a text
/// column — optional purple "New" label, title, creator row, views · age.
class SubscriptionEpisodeCard extends ConsumerWidget {
  const SubscriptionEpisodeCard({super.key, required this.episode, this.onTap});

  final SubscriptionEpisode episode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creator = ref.watch(subscriptionsProvider).creatorOf(episode);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _thumbnail(),
          const SizedBox(width: SkifluxSpacing.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (episode.isNew) ...[
                  Text(
                    'New',
                    style: SkifluxTypography.bodyP11Semibold.copyWith(
                      color: SkifluxColors.contentBrand,
                    ),
                  ),
                  const SizedBox(height: SkifluxSpacing.space2xs),
                ],
                Text(
                  episode.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SkifluxTypography.headingH10Bold.copyWith(
                    color: SkifluxColors.contentPrimary,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceXs),
                Row(
                  children: [
                    SkifluxAvatar(
                      style: SkifluxAvatarStyle.initial,
                      // Figma: 16px inline avatar.
                      size: SkifluxIcons.sizeS,
                      initials: creator.initials,
                    ),
                    const SizedBox(width: SkifluxSpacing.spaceXs),
                    Flexible(
                      child: Text(
                        creator.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        // Figma: Creato Bold 12 on content/tertiary.
                        style: SkifluxTypography.uiInputContent.copyWith(
                          color: SkifluxColors.contentTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SkifluxSpacing.space2xs),
                Text(
                  episode.meta,
                  style: SkifluxTypography.bodyP11Regular.copyWith(
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

  Widget _thumbnail() {
    return ClipRRect(
      borderRadius: SkifluxRadii.borderL,
      child: SizedBox(
        width: 128,
        height: 98,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Real `thumbnail_url` from the /episodes/following payload;
            // bundled art only as the offline/missing fallback (same
            // network→asset pattern as the feed card cover).
            if (episode.hasThumbnail)
              SkifluxNetworkImage(
                url: episode.thumbnailUrl!,
                errorWidget: Image.asset(
                  'assets/home_video_raw1.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: SkifluxColors.magenta900),
                ),
              )
            else
              Image.asset(
                'assets/home_video_raw1.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: SkifluxColors.magenta900),
              ),
            Positioned(
              top: SkifluxSpacing.spaceS,
              left: SkifluxSpacing.spaceS,
              child: _chip(episode.epTag),
            ),
            Positioned(
              bottom: SkifluxSpacing.spaceS,
              right: SkifluxSpacing.spaceS,
              child: _chip(episode.duration),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SkifluxSpacing.spaceXs,
        vertical: SkifluxSpacing.space2xs,
      ),
      decoration: BoxDecoration(
        // Figma: Overlay/50 scrim chip with radius/x corners.
        color: SkifluxColors.overlay50,
        borderRadius: BorderRadius.circular(SkifluxRadii.x),
      ),
      child: Text(
        label,
        style: SkifluxTypography.bodyP11Semibold.copyWith(
          color: SkifluxColors.contentPrimaryInverse,
        ),
      ),
    );
  }
}

// ── All Subscriptions row (flow 01) ──────────────────────────────────

/// Creator row: avatar (purple unseen dot), name + handle, trailing bell
/// pill that opens the notification-level dropdown (All / Personalized /
/// None / Unsubscribe).
class SubscribedCreatorRow extends StatelessWidget {
  const SubscribedCreatorRow({
    super.key,
    required this.creator,
    required this.onBellTap,
    this.onTap,
  });

  final SubscribedCreator creator;
  final VoidCallback onBellTap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SkifluxSpacing.spaceS),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SkifluxAvatar(
                  style: SkifluxAvatarStyle.initial,
                  size: SkifluxUnit.u48,
                  initials: creator.initials,
                ),
                if (creator.hasUnseen)
                  const Positioned(
                    left: 0,
                    bottom: 0,
                    // Figma: unseen dot is brand purple, not the red
                    // notification default.
                    child: SkifluxNotificationBadge(
                      type: SkifluxBadgeType.indicator,
                      backgroundColor: SkifluxColors.contentBrand,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: SkifluxSpacing.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    creator.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SkifluxTypography.headingH10Bold.copyWith(
                      color: SkifluxColors.contentPrimary,
                    ),
                  ),
                  const SizedBox(height: SkifluxSpacing.space2xs),
                  Text(
                    creator.handle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SkifluxTypography.bodyP11Regular.copyWith(
                      color: SkifluxColors.contentTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: SkifluxSpacing.spaceM),
            _BellPill(mode: creator.notificationMode, onTap: onBellTap),
          ],
        ),
      ),
    );
  }
}

/// Grey pill with bell + chevron — reflects the creator's notification
/// level. All = filled purple bell; Personalized = outline bell; None =
/// bell-off. Tapping opens the dropdown sheet.
class _BellPill extends StatelessWidget {
  const _BellPill({required this.mode, required this.onTap});

  final CreatorNotificationMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (mode) {
      CreatorNotificationMode.all => (
        RemixIcons.notification_fill,
        SkifluxColors.contentBrand,
      ),
      CreatorNotificationMode.personalized => (
        RemixIcons.notification_line,
        SkifluxColors.contentSecondary,
      ),
      CreatorNotificationMode.none => (
        RemixIcons.notification_off_line,
        SkifluxColors.contentSecondary,
      ),
    };
    return Material(
      color: SkifluxColors.backgroundHover,
      borderRadius: SkifluxRadii.borderPill,
      child: InkWell(
        borderRadius: SkifluxRadii.borderPill,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SkifluxSpacing.spaceM,
            vertical: SkifluxSpacing.spaceS,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: SkifluxIcons.sizeS, color: color),
              const SizedBox(width: SkifluxSpacing.space2xs),
              const Icon(
                RemixIcons.arrow_down_s_line,
                size: SkifluxIcons.sizeS,
                color: SkifluxColors.contentSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
