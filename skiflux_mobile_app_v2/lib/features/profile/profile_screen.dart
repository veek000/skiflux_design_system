import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/error_handling/error_display.dart';
import '../../shared/sheets/share_sheet.dart';
import '../../shared/toast/skiflux_toast.dart';
import '../../shared/widgets/load_failure.dart';
import '../../shared/widgets/playlist_deck.dart';
import '../home/sheets/episode_unlock_sheet.dart';
import '../home/sheets/notify_settings_sheet.dart';
import '../playlists/data/playlists_store.dart';
import '../playlists/playlist_screen.dart';
import '../subscriptions/data/subscriptions_store.dart';
import '../subscriptions/subscriptions_screen.dart';
import 'data/creator_profile_provider.dart';

/// Figma: **Home & In-app Flow 07** (`198:14048`) — Profile screen.
///
/// Top nav, creator header (Subscribe / Notify), Recent | Playlists tabs,
/// pill filter group, and episode cards (Completed / Unlocked / Locked).
///
/// [creatorId] is the backend creator **UUID** — `GET /creators/{id}` takes
/// no username. Subscribe runs the real follow toggle through
/// [subscriptionsProvider]; there is no local subscribed flag.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({
    super.key,
    required this.creatorId,
  });

  final String creatorId;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _tabIndex = 0;
  int _pillIndex = 0;

  /// Notify preference is device-local only — the spec has no per-creator
  /// notification endpoint, so this is never claimed to sync.
  NotifyPreference _notify = NotifyPreference.personalized;

  static const _pills = ['All', 'UI', 'Code', 'Motion', 'Brand'];

  Future<void> _toggleFollow(CreatorProfile profile, bool subscribed) async {
    final notifier = ref.read(subscriptionsProvider.notifier);
    try {
      if (subscribed) {
        await notifier.unsubscribe(
          SubscribedCreator(
            id: profile.id,
            name: profile.name,
            username: profile.username,
            initials: profile.initials,
          ),
        );
        if (!mounted) return;
        SkifluxToast.success(context, 'Unsubscribed');
      } else {
        await notifier.subscribe(
          SubscribedCreator(
            id: profile.id,
            name: profile.name,
            username: profile.username,
            initials: profile.initials,
          ),
        );
        if (!mounted) return;
        SkifluxToast.success(context, 'Subscribed to ${profile.name}');
      }
      // The payload's is_following / followers_count are now stale.
      ref.invalidate(creatorProfileProvider(widget.creatorId));
    } catch (e, st) {
      if (!mounted) return;
      await ErrorDisplay.show(context, ref, e, stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Profile',
        // Figma: screen title uses Heading Style/Heading H8 Bold.
        labelStyle: SkifluxTypography.headingH8Bold,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(RemixIcons.arrow_left_s_line),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(RemixIcons.share_forward_fill),
          onPressed: () => showShareSheet(context),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ref.watch(creatorProfileProvider(widget.creatorId)).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => LoadFailure(
            error: e,
            title: "We couldn't load this profile",
            onRetry: () => ref
                .read(creatorProfileProvider(widget.creatorId).notifier)
                .retry(),
          ),
          data: (profile) {
            final subs = ref.watch(subscriptionsProvider);
            // Follow list loaded → membership is the truth (it reflects
            // optimistic toggles instantly); otherwise the profile payload's
            // own is_following.
            final subscribed = subs.hasLoaded
                ? subs.isSubscribed(
                    profile.id.isNotEmpty ? profile.id : profile.username,
                  )
                : profile.isFollowing;
            return ListView(
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              children: [
                _ProfileHeader(
                  profile: profile,
                  subscribed: subscribed,
                  onSubscribe: () => _toggleFollow(profile, subscribed),
                  onNotify: () async {
                    final next = await showNotifySettingsSheet(
                      context,
                      current: _notify,
                    );
                    if (next == null || !context.mounted) return;
                    setState(() => _notify = next);
                    // Honest scope: nothing syncs — the backend has no
                    // per-creator notification preference endpoint.
                    SkifluxToast.info(
                      context,
                      '${next.toastTitle} (saved on this device only)',
                    );
                  },
                ),
                const SizedBox(height: SkifluxSpacing.spaceL),
                _Tabs(
                  index: _tabIndex,
                  onChanged: (i) => setState(() => _tabIndex = i),
                ),
                const SizedBox(height: SkifluxSpacing.spaceL),
                if (_tabIndex == 0) ...[
                  _pillGroup(),
                  const SizedBox(height: SkifluxSpacing.spaceL),
                  ..._recentEpisodes(context),
                ] else ...[
                  _playlistTile(context),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _recentEpisodes(BuildContext context) {
    final eps = ref.watch(playlistsProvider).defaultPlaylist.episodes.take(4);
    final widgets = <Widget>[];
    for (final ep in eps) {
      widgets.add(
        _EpisodeCard(
          episode: ep.epTag,
          status: switch (ep.state) {
            PlaylistEpisodeState.completed => 'Completed',
            PlaylistEpisodeState.unlocked => 'Unlocked',
            PlaylistEpisodeState.locked => 'Locked',
          },
          statusColor: switch (ep.state) {
            PlaylistEpisodeState.completed => SkifluxColors.contentPositive,
            PlaylistEpisodeState.unlocked => SkifluxColors.contentNotice,
            PlaylistEpisodeState.locked => SkifluxColors.contentTertiary,
          },
          showDuration: true,
          progress: ep.state == PlaylistEpisodeState.completed ? 1 : null,
          locked: ep.isLocked,
          coinPrice: ep.isLocked ? ep.coinCost : null,
          title: ep.title,
          onTap: () async {
            if (ep.isLocked) {
              await showEpisodeUnlockSheet(context, episodeId: ep.id);
              setState(() {});
              return;
            }
            // Play in subscription-style episode modal (Home Flow 03 pattern).
            final sub = SubscriptionEpisode(
              epNumber: ep.number,
              title: ep.title,
              creatorUsername: 'amara',
              duration: ep.duration,
              views: '22k',
              postedAgo: '5 hrs ago',
              watchProgress: ep.state == PlaylistEpisodeState.completed
                  ? 1
                  : 0.2,
            );
            if (!context.mounted) return;
            await showEpisodePlayerModal(context, sub);
          },
        ),
      );
      widgets.add(const SizedBox(height: SkifluxSpacing.spaceL));
    }
    return widgets;
  }

  /// Playlist preview — same rendering as the search playlist result row
  /// (Figma `304:9582`): stacked deck thumbnail + title + creator · count.
  Widget _playlistTile(BuildContext context) {
    final pl = ref.watch(playlistsProvider).defaultPlaylist;
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const PlaylistScreen())),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 98,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlaylistDeck(width: 126, height: 98, episodeCount: pl.episodeCount),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SkifluxSpacing.spaceS,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pl.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SkifluxTypography.headingH10Bold.copyWith(
                        color: SkifluxColors.contentPrimary,
                      ),
                    ),
                    Text(
                      pl.metaLine,
                      style: SkifluxTypography.bodyP11Regular.copyWith(
                        color: SkifluxColors.contentPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillGroup() {
    // Figma: Button Group Pill (198:14072) — Button component, size S.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < _pills.length; i++) ...[
            if (i > 0) const SizedBox(width: SkifluxSpacing.spaceS),
            SkifluxButton(
              label: _pills[i],
              size: SkifluxButtonSize.s,
              type: i == _pillIndex
                  ? SkifluxButtonType.primary
                  : SkifluxButtonType.secondary,
              onPressed: () => setState(() => _pillIndex = i),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.subscribed,
    required this.onSubscribe,
    required this.onNotify,
  });

  final CreatorProfile profile;
  final bool subscribed;
  final VoidCallback onSubscribe;
  final VoidCallback onNotify;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SkifluxAvatar(
          style: SkifluxAvatarStyle.initial,
          size: SkifluxUnit.u64,
          initials: profile.initials,
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        Text(
          profile.name,
          style: SkifluxTypography.headingH5Bold.copyWith(
            color: SkifluxColors.contentPrimary,
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceXs),
        Text(
          profile.handle,
          style: SkifluxTypography.bodyP11Regular.copyWith(
            color: SkifluxColors.contentPrimary,
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        Row(
          children: [
            Expanded(
              child: SkifluxButton(
                label: subscribed ? 'Subscribed' : 'Subscribe',
                size: SkifluxButtonSize.s,
                type: subscribed
                    ? SkifluxButtonType.secondary
                    : SkifluxButtonType.primary,
                expanded: true,
                onPressed: onSubscribe,
              ),
            ),
            const SizedBox(width: SkifluxSpacing.spaceS),
            Expanded(
              child: SkifluxButton(
                label: 'Notify',
                size: SkifluxButtonSize.s,
                type: SkifluxButtonType.secondary,
                expanded: true,
                leadingIcon: const Icon(RemixIcons.notification_3_line),
                onPressed: onNotify,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _labels = ['Recent', 'Playlists'];

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
          for (var i = 0; i < _labels.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: SkifluxSpacing.spaceS,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == index
                            ? SkifluxColors.contentBrand
                            : Colors.transparent,
                        width: SkifluxBorderWidth.xs,
                      ),
                    ),
                  ),
                  child: Text(
                    _labels[i],
                    textAlign: TextAlign.center,
                    style: SkifluxTypography.uiButtonMedium.copyWith(
                      color: i == index
                          ? SkifluxColors.contentBrand
                          : SkifluxColors.contentDisabled,
                      fontWeight: i == index
                          ? SkifluxFontWeight.bold
                          : SkifluxFontWeight.medium,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EpisodeCard extends StatelessWidget {
  const _EpisodeCard({
    required this.episode,
    required this.status,
    required this.statusColor,
    this.showDuration = false,
    this.progress,
    this.locked = false,
    this.coinPrice,
    this.title = 'Introduction to UI Design Thinking',
    this.onTap,
  });

  final String episode;
  final String status;
  final Color statusColor;
  final bool showDuration;
  final double? progress;
  final bool locked;
  final int? coinPrice;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: SkifluxRadii.borderL,
      child: Row(
        children: [
          _thumbnail(),
          const SizedBox(width: SkifluxSpacing.spaceS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceXs),
                Text(
                  title,
                  style: SkifluxTypography.headingH10Bold.copyWith(
                    color: SkifluxColors.contentPrimary,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceXs),
                Text(
                  '22k views · 5 hrs ago',
                  style: SkifluxTypography.bodyP11Regular.copyWith(
                    color: SkifluxColors.contentTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          if (locked && coinPrice != null) _coinBadge() else _playButton(),
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
            // TODO(backend, blocking): replace local placeholder asset with real CDN/backend episode thumbnail URL — expects: String (network URL)
            Image.asset('assets/home_video_cover.png', fit: BoxFit.cover),
            if (locked) ...[
              const ColoredBox(color: SkifluxColors.overlay50),
              const Center(
                child: Icon(
                  RemixIcons.lock_2_fill,
                  size: SkifluxIcons.sizeM,
                  color: SkifluxColors.contentPrimaryInverse,
                ),
              ),
            ],
            // EP badge (top-left, Content/Brand pill).
            Positioned(
              top: SkifluxSpacing.spaceS,
              left: SkifluxSpacing.spaceS,
              child: _pill(episode, background: SkifluxColors.contentBrand),
            ),
            if (showDuration)
              Positioned(
                bottom: SkifluxSpacing.spaceS,
                right: SkifluxSpacing.spaceS,
                child: _pill('20:00', background: SkifluxColors.overlay50),
              ),
            if (progress != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SizedBox(
                  height: SkifluxSpacing.spaceXs,
                  child: Stack(
                    children: [
                      const ColoredBox(color: SkifluxColors.backgroundSelected),
                      FractionallySizedBox(
                        widthFactor: progress!.clamp(0, 1),
                        child: const ColoredBox(
                          color: SkifluxColors.contentBrand,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, {required Color background}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SkifluxSpacing.spaceS,
        vertical: SkifluxSpacing.space2xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: SkifluxRadii.borderX,
      ),
      child: Text(
        label,
        style: SkifluxTypography.bodyP11Semibold.copyWith(
          color: SkifluxColors.contentPrimaryInverse,
        ),
      ),
    );
  }

  Widget _playButton() {
    return const Icon(
      RemixIcons.play_circle_fill,
      size: SkifluxIcons.sizeM,
      color: SkifluxColors.contentDisabled,
    );
  }

  Widget _coinBadge() {
    // Figma: Background/Notice Subtle pill + copper coin + price.
    return Container(
      padding: const EdgeInsets.only(
        left: SkifluxSpacing.spaceXs,
        right: SkifluxSpacing.spaceS,
        top: SkifluxSpacing.spaceXs,
        bottom: SkifluxSpacing.spaceXs,
      ),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundNoticeSubtle,
        borderRadius: SkifluxRadii.borderPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            RemixIcons.copper_coin_fill,
            size: SkifluxIcons.sizeS,
            color: SkifluxColors.contentNotice,
          ),
          const SizedBox(width: SkifluxSpacing.space2xs),
          Text(
            '$coinPrice',
            style: SkifluxTypography.uiBadgeTagMedium.copyWith(
              color: SkifluxColors.contentNoticeBold,
            ),
          ),
        ],
      ),
    );
  }
}
