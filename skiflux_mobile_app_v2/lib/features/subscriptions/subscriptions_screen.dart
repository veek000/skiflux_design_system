import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/skiflux_sheet.dart';
import '../../shared/widgets/video_feed_card.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import '../home/sheets/playback_speed_sheet.dart';
import '../playlists/data/playlists_store.dart';
import '../playlists/playlist_screen.dart';
import 'all_subscriptions_screen.dart';
import 'data/subscriptions_store.dart';
import 'filter_sheet.dart';
import 'subscription_widgets.dart';

/// Figma: **Subscription Flows 04 & 05** (`1256:29567` / `1256:29405`)
///
/// Body of the bottom-nav Subscriptions tab (the tab bar itself lives in
/// HomeScreen's scaffold). Shows the empty state when nothing is
/// subscribed, otherwise stories row + "Latest from Creators" feed.
class SubscriptionsBody extends StatefulWidget {
  const SubscriptionsBody({super.key});

  @override
  State<SubscriptionsBody> createState() => _SubscriptionsBodyState();
}

class _SubscriptionsBodyState extends State<SubscriptionsBody> {
  SubscriptionFeedFilter _filter = SubscriptionFeedFilter.recent;

  @override
  Widget build(BuildContext context) {
    final creators = SubscriptionsStore.creators;
    return Column(
      children: [
        SubscriptionsTopBar(
          title: 'Subscriptions',
          onSearch: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          ),
          onNotification: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
        Expanded(
          child: creators.isEmpty ? _emptyState(context) : _feed(creators),
        ),
      ],
    );
  }

  // ── Flow 04 — empty state ──────────────────────────────────────────

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SkifluxEmptyState(
            icon: Icon(
              RemixIcons.user_search_fill,
              size: SkifluxSpacing.space4xl,
              color: SkifluxColors.contentBrand,
            ),
            title: 'No subscriptions yet',
            message: 'Follow creators to see their new episodes here. '
                'Subscribed creators appear as stories at the top so you '
                'never miss a drop.',
          ),
          const SizedBox(height: SkifluxSpacing.spaceXl),
          SkifluxButton(
            label: 'Find Creators to follow',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
        ],
      ),
    );
  }

  // ── Flow 05 — populated feed ───────────────────────────────────────

  Widget _feed(List<SubscribedCreator> creators) {
    final episodes = SubscriptionsStore.feed(filter: _filter);
    return ListView(
      padding: const EdgeInsets.only(top: SkifluxSpacing.spaceL),
      children: [
        SubscriptionStoriesRow(
          creators: creators,
          onRefresh: () => setState(() {}),
        ),
        const SizedBox(height: SkifluxSpacing.spaceXl),
        Row(
          children: [
            Expanded(
              child: Text(
                'Latest from Creators',
                style: SkifluxTypography.headingH8Bold.copyWith(
                  color: SkifluxColors.contentPrimary,
                ),
              ),
            ),
            _FilterControl(
              filter: _filter,
              onTap: () async {
                final picked = await showSubscriptionFilterSheet(
                  context,
                  current: _filter,
                );
                if (picked != null) setState(() => _filter = picked);
              },
            ),
          ],
        ),
        const SizedBox(height: SkifluxSpacing.spaceL),
        if (episodes.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: SkifluxSpacing.space4xl),
            child: SkifluxEmptyState(
              icon: const Icon(
                RemixIcons.search_eye_line,
                size: SkifluxSpacing.space4xl,
                color: SkifluxColors.contentBrand,
              ),
              title: 'Nothing here yet',
              message:
                  'No episodes match "${_filter.label}". Try another filter.',
            ),
          )
        else
          for (final (i, episode) in episodes.indexed) ...[
            if (i > 0) const SizedBox(height: SkifluxSpacing.spaceL),
            SubscriptionEpisodeCard(
              episode: episode,
              onTap: () => showEpisodePlayerModal(context, episode),
            ),
          ],
        const SizedBox(height: SkifluxSpacing.spaceL),
      ],
    );
  }
}

/// "Recent ⌄"-style trailing control that opens the filter sheet.
class _FilterControl extends StatelessWidget {
  const _FilterControl({required this.filter, required this.onTap});

  final SubscriptionFeedFilter filter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            // Funnel icon — same as the All-Subscriptions "Filter" link.
            RemixIcons.filter_fill,
            size: SkifluxIcons.sizeS,
            color: SkifluxColors.contentSecondary,
          ),
          const SizedBox(width: SkifluxSpacing.space2xs),
          Text(
            filter.label,
            style: SkifluxTypography.bodyP9Semibold.copyWith(
              color: SkifluxColors.contentSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared pieces (also used by the creator channel screen) ──────────

/// Top bar: leading circle · centered title · optional notification circle
/// (Subscriptions tab only — pushed screens like the creator channel drop
/// it per Figma).
class SubscriptionsTopBar extends StatelessWidget {
  const SubscriptionsTopBar({
    super.key,
    required this.title,
    this.onSearch,
    this.onNotification,
    this.leading,
    this.showNotification = true,
  });

  final String title;
  final VoidCallback? onSearch;

  /// Bell tap — Tasks / Subscriptions tab roots push NotificationsScreen.
  final VoidCallback? onNotification;

  /// Overrides the leading search circle (creator channel uses a back
  /// chevron instead).
  final Widget? leading;

  /// Figma flow 03 has no notification control — only the tab root does.
  final bool showNotification;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SkifluxUnit.u48,
      child: Row(
        children: [
          leading ??
              CircleTapTarget(
                icon: RemixIcons.search_fill,
                onTap: onSearch,
              ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SkifluxTypography.headingH7Bold.copyWith(
                color: SkifluxColors.contentPrimary,
              ),
            ),
          ),
          if (showNotification)
            CircleTapTarget(
              icon: RemixIcons.notification_3_fill,
              onTap: onNotification,
              badge: const SkifluxNotificationBadge(
                type: SkifluxBadgeType.indicator,
              ),
            )
          else
            // Invisible 48px spacer keeps the title optically centered.
            const SizedBox(width: SkifluxUnit.u48),
        ],
      ),
    );
  }
}

/// 48px grey circle icon button (same treatment as the home top bar).
class CircleTapTarget extends StatelessWidget {
  const CircleTapTarget({
    super.key,
    required this.icon,
    this.onTap,
    this.badge,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    Widget glyph = Icon(
      icon,
      size: SkifluxIcons.sizeM,
      color: SkifluxColors.contentPrimary,
    );
    if (badge != null) {
      glyph = Stack(
        clipBehavior: Clip.none,
        children: [
          glyph,
          Positioned(
            top: -SkifluxSpacing.space2xs,
            right: -SkifluxSpacing.space2xs,
            child: badge!,
          ),
        ],
      );
    }
    return Material(
      color: SkifluxColors.backgroundHover,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: SkifluxUnit.u48,
          height: SkifluxUnit.u48,
          child: Center(child: glyph),
        ),
      ),
    );
  }
}

/// Horizontal stories rail: View-all tile + creator avatars w/ new badges.
class SubscriptionStoriesRow extends StatelessWidget {
  const SubscriptionStoriesRow({
    super.key,
    required this.creators,
    this.activeUsername,
    this.onRefresh,
  });

  final List<SubscribedCreator> creators;

  /// Rings this creator's avatar (creator channel, flow 03).
  final String? activeUsername;

  /// Called after returning from pushed screens so bell/unseen state
  /// changes made there re-render here.
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Ring-padded 48px avatar (56) + name + "N new" badge.
      height: 108,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ViewAllStoryTile(
            creatorCount: creators.length,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AllSubscriptionsScreen(),
                ),
              );
              onRefresh?.call();
            },
          ),
          for (final creator in creators) ...[
            const SizedBox(width: SkifluxSpacing.spaceL),
            CreatorStoryTile(
              creator: creator,
              active: creator.username == activeUsername,
              onTap: creator.username == activeUsername
                  ? null
                  : () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              CreatorChannelScreen(creator: creator),
                        ),
                      );
                      onRefresh?.call();
                    },
            ),
          ],
        ],
      ),
    );
  }
}

// ── Flow 03 — creator channel ────────────────────────────────────────

/// Figma: **Subscription Flow 03** (`1256:29613`) — pushed from a story
/// avatar. Stories rail persists; feed is filtered to one creator.
class CreatorChannelScreen extends StatefulWidget {
  const CreatorChannelScreen({super.key, required this.creator});

  final SubscribedCreator creator;

  @override
  State<CreatorChannelScreen> createState() => _CreatorChannelScreenState();
}

class _CreatorChannelScreenState extends State<CreatorChannelScreen> {
  @override
  Widget build(BuildContext context) {
    final episodes =
        SubscriptionsStore.feed(creatorUsername: widget.creator.username);
    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SkifluxSpacing.spaceL,
          ),
          child: Column(
            children: [
              const SizedBox(height: SkifluxSpacing.spaceL),
              SubscriptionsTopBar(
                title: widget.creator.name,
                showNotification: false,
                leading: CircleTapTarget(
                  icon: RemixIcons.arrow_left_s_line,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: SkifluxSpacing.spaceL),
              Expanded(
                child: ListView(
                  children: [
                    SubscriptionStoriesRow(
                      creators: SubscriptionsStore.creators,
                      activeUsername: widget.creator.username,
                      onRefresh: () => setState(() {}),
                    ),
                    const SizedBox(height: SkifluxSpacing.spaceXl),
                    _creatorHeader(context),
                    const SizedBox(height: SkifluxSpacing.spaceL),
                    for (final (i, episode) in episodes.indexed) ...[
                      if (i > 0)
                        const SizedBox(height: SkifluxSpacing.spaceL),
                      SubscriptionEpisodeCard(
                        episode: episode,
                        onTap: () => showEpisodePlayerModal(context, episode),
                      ),
                    ],
                    const SizedBox(height: SkifluxSpacing.spaceL),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Amara Design / @amara" + trailing "Visit Profile →" outlined pill.
  Widget _creatorHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.creator.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // Figma: Heading H9 semibold (Creato Medium 18).
                style: SkifluxTypography.headingH9Semibold.copyWith(
                  color: SkifluxColors.contentPrimary,
                ),
              ),
              const SizedBox(height: SkifluxSpacing.space2xs),
              Text(
                widget.creator.handle,
                // Figma: Creato Bold 12 on content/tertiary.
                style: SkifluxTypography.uiInputContent.copyWith(
                  color: SkifluxColors.contentTertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: SkifluxSpacing.spaceM),
        // Figma: filled grey pill (content/secondary-inverse #e5e5e5), no
        // border — none of the SkifluxButton types are a grey fill, so
        // it's composed from tokens here.
        Material(
          color: SkifluxColors.contentSecondaryInverse,
          borderRadius: SkifluxRadii.borderPill,
          child: InkWell(
            borderRadius: SkifluxRadii.borderPill,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SkifluxSpacing.spaceS,
                vertical: SkifluxSpacing.spaceXs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SkifluxSpacing.spaceXs,
                    ),
                    child: Text(
                      'Visit Profile',
                      style: SkifluxTypography.uiButtonSmall.copyWith(
                        color: SkifluxColors.contentPrimary,
                      ),
                    ),
                  ),
                  const Icon(
                    RemixIcons.arrow_right_line,
                    size: SkifluxIcons.sizeS,
                    color: SkifluxColors.contentPrimary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Flow 02 — episode player modal ───────────────────────────────────

/// Figma `1256:29748` — modal sheet sliding over the current screen
/// (previous screen stays visible, dimmed, behind the rounded top): white
/// header with episode title + "View Playlist ›" link + close circle,
/// then the home player inset with rounded corners underneath.
Future<void> showEpisodePlayerModal(
  BuildContext context,
  SubscriptionEpisode episode,
) {
  return showSkifluxSheet<void>(
    context: context,
    builder: (_) => EpisodePlayerSheet(episode: episode),
  );
}

/// Figma Home Flow 03 (`827:36229`) + Subscription Flow 02 player modal:
/// title, View Playlist, video card, scrubber + CC / speed / minimize.
class EpisodePlayerSheet extends StatefulWidget {
  const EpisodePlayerSheet({super.key, required this.episode});

  final SubscriptionEpisode episode;

  @override
  State<EpisodePlayerSheet> createState() => _EpisodePlayerSheetState();
}

class _EpisodePlayerSheetState extends State<EpisodePlayerSheet> {
  // Demo scrub position (static visual matching Figma ~00:01 of 12:03).
  double _progress = 1 / (12 * 60 + 3);

  SubscriptionEpisode get episode => widget.episode;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final prefs = PlayerPrefsStore.instance;
    return Material(
      color: SkifluxColors.backgroundPrimary,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(SkifluxRadii.x),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: media.size.height - media.padding.top - SkifluxUnit.u48,
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  SkifluxSpacing.spaceL,
                  0,
                  SkifluxSpacing.spaceL,
                  SkifluxSpacing.spaceS,
                ),
                child: VideoFeedCard(
                  epTag: episode.epTag,
                  title: episode.title,
                  description: SubscriptionsStore.creatorOf(episode).name,
                ),
              ),
            ),
            // Scrubber + transport chrome (Home Flow 03).
            Padding(
              padding: EdgeInsets.fromLTRB(
                SkifluxSpacing.spaceL,
                0,
                SkifluxSpacing.spaceL,
                SkifluxSpacing.spaceL + media.padding.bottom,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        _format(Duration(seconds: (_progress * 723).round())),
                        style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                          color: SkifluxColors.contentTertiary,
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                            activeTrackColor: SkifluxColors.contentBrand,
                            inactiveTrackColor:
                                SkifluxColors.backgroundPressed,
                            thumbColor: SkifluxColors.contentBrand,
                          ),
                          child: Slider(
                            value: _progress.clamp(0, 1),
                            onChanged: (v) => setState(() => _progress = v),
                          ),
                        ),
                      ),
                      Text(
                        '12:03',
                        style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                          color: SkifluxColors.contentTertiary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ListenableBuilder(
                        listenable: prefs,
                        builder: (_, __) => _ChromeChip(
                          label: prefs.captionsOn ? 'CC On' : 'CC',
                          selected: prefs.captionsOn,
                          onTap: prefs.toggleCaptions,
                        ),
                      ),
                      const SizedBox(width: SkifluxSpacing.spaceS),
                      ListenableBuilder(
                        listenable: prefs,
                        builder: (_, __) => _ChromeChip(
                          label: prefs.speedLabel,
                          selected: prefs.speed != 1.0,
                          onTap: () => showPlaybackSpeedSheet(context),
                        ),
                      ),
                      const SizedBox(width: SkifluxSpacing.spaceS),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(RemixIcons.picture_in_picture_2_line),
                        color: SkifluxColors.contentPrimary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SkifluxSpacing.spaceL,
        SkifluxSpacing.spaceL,
        SkifluxSpacing.spaceL,
        SkifluxSpacing.spaceS,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  episode.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SkifluxTypography.headingH9Bold.copyWith(
                    color: SkifluxColors.contentPrimary,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.space2xs),
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PlaylistScreen(),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Playlist',
                        style: SkifluxTypography.bodyP10Regular.copyWith(
                          color: SkifluxColors.contentLink,
                        ),
                      ),
                      const SizedBox(width: SkifluxSpacing.spaceXs),
                      const Icon(
                        RemixIcons.arrow_right_s_line,
                        size: SkifluxIcons.sizeS,
                        color: SkifluxColors.contentLink,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: SkifluxSpacing.spaceL),
          CircleTapTarget(
            icon: RemixIcons.close_line,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _ChromeChip extends StatelessWidget {
  const _ChromeChip({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? SkifluxColors.backgroundSelected
          : SkifluxColors.backgroundHover,
      borderRadius: SkifluxRadii.borderPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: SkifluxRadii.borderPill,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SkifluxSpacing.spaceM,
            vertical: SkifluxSpacing.spaceS,
          ),
          child: Text(
            label,
            style: SkifluxTypography.uiButtonSmall.copyWith(
              color: selected
                  ? SkifluxColors.contentBrand
                  : SkifluxColors.contentPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
