import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/error_handling/error_display.dart';
import '../../shared/sheets/share_sheet.dart';
import '../../shared/toast/skiflux_toast.dart';
import '../../shared/widgets/load_failure.dart';
import '../../shared/widgets/network_image.dart';
import '../../shared/widgets/playlist_deck.dart';
import '../home/sheets/episode_unlock_sheet.dart';
import '../home/sheets/notify_settings_sheet.dart';
import '../playlists/data/playlists_store.dart';
import '../playlists/data/season_providers.dart';
import '../playlists/playlist_screen.dart';
import '../subscriptions/data/subscriptions_store.dart';
import '../subscriptions/subscriptions_screen.dart';
import 'data/creator_profile_provider.dart';
import 'data/skill_world_store.dart';

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

  /// The selected skillworld filter, as its backend value. Null is "All".
  ///
  /// Held as the wire value rather than an index because the pill row is built
  /// from whatever worlds this creator actually publishes in — an index would
  /// point at a different world once that list changes under a refresh.
  String? _world;

  /// Notify preference is device-local only — the spec has no per-creator
  /// notification endpoint, so this is never claimed to sync.
  NotifyPreference _notify = NotifyPreference.personalized;

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
          // Null until `GET /creators/{id}` answers — the share then carries
          // nothing and is skipped, rather than naming a creator we can't yet.
          onPressed: () {
            final creator = ref
                .read(creatorProfileProvider(widget.creatorId))
                .value;
            showShareSheet(
              context,
              title: creator == null
                  ? null
                  : '${creator.name} ${creator.handle} on SkiFlux'.trim(),
            );
          },
        ),
      ),
      body: SafeArea(
        top: false,
        child: ref.watch(creatorProfileProvider(widget.creatorId)).when(
          loading: () => const _ProfileSkeleton(),
          error: (e, st) => LoadFailure(
            error: e,
            title: "We couldn't load this profile",
            onRetry: () => ref
                .read(creatorProfileProvider(widget.creatorId).notifier)
                .retry(),
          ),
          data: (profile) {
            final subs = ref.watch(subscriptionsProvider);
            // Seasons are matched on the id *or* the username: the id can come
            // back empty, and it is not guaranteed to share a namespace with
            // the one on `SeasonList.creator`.
            final creator = CreatorRef(
              id: profile.id,
              username: profile.username,
            );
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
                  _pillGroup(creator),
                  _recentEpisodes(context, creator),
                ] else
                  _playlists(context, creator),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The creator's own uploads, newest first — four of them, optionally
  /// narrowed to the selected skillworld.
  ///
  /// This used to read a globally shared, hardcoded playlist, so every creator
  /// in the app showed the same eight episodes by someone else.
  Widget _recentEpisodes(BuildContext context, CreatorRef creator) {
    final async = ref.watch(creatorRecentEpisodesProvider(creator));

    return switch (async) {
      AsyncLoading() => const _EpisodeListSkeleton(),
      AsyncError(:final error) => LoadFailure(
        error: error,
        title: "We couldn't load these uploads",
        onRetry: () => ref.invalidate(creatorRecentEpisodesProvider(creator)),
      ),
      AsyncValue(:final value?) => _recentList(context, value),
    };
  }

  Widget _recentList(BuildContext context, List<PlaylistEpisode> all) {
    final world = _world;
    final eps = (world == null
            ? all
            : all.where((e) => e.skillworld == world).toList(growable: false))
        .take(4)
        .toList(growable: false);

    if (eps.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: SkifluxSpacing.space2xl),
        child: SkifluxEmptyState(
          icon: Icon(
            RemixIcons.video_on_fill,
            size: SkifluxEmptyState.iconSize,
            color: SkifluxColors.contentBrand,
          ),
          title: 'No uploads yet',
          message: "Nothing published here so far. Check back later.",
        ),
      );
    }

    return Column(
      children: [
        for (final ep in eps) ...[
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
            duration: ep.duration,
            meta: ep.metaLine,
            progress: ep.state == PlaylistEpisodeState.completed ? 1 : null,
            locked: ep.isLocked,
            coinPrice: ep.isLocked ? ep.coinCost : null,
            title: ep.title,
            // The episode's own artwork. Every row on every creator's profile
            // used to draw the same bundled `home_video_cover.png`.
            thumbnailUrl: ep.thumbnailUrl,
            onTap: () => _openEpisode(context, ep),
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
        ],
      ],
    );
  }

  Future<void> _openEpisode(BuildContext context, PlaylistEpisode ep) async {
    if (ep.isLocked) {
      await showEpisodeUnlockSheet(context, episodeId: ep.id);
      if (mounted) setState(() {});
      return;
    }
    // A profile has no feed behind it, so this is the player modal (Home Flow
    // 03 pattern) rather than an inline jump.
    final season = ref.read(playlistsProvider).seasonOf(ep.id);
    final sub = SubscriptionEpisode(
      id: ep.id,
      epNumber: ep.number,
      title: ep.title,
      creatorUsername: season?.creatorUsername ?? '',
      creatorId: season?.creatorId ?? '',
      creatorName: season?.creatorName ?? '',
      duration: ep.duration,
      // Real figures or none. Both of these were hardcoded ("22k", "5 hrs
      // ago") on every episode of every creator.
      views: ep.viewCount == null ? '' : '${countLabel(ep.viewCount!)} views',
      postedAgo: ep.createdAt == null ? '' : relativeAgeLabel(ep.createdAt),
      watchProgress: ep.state == PlaylistEpisodeState.completed ? 1 : 0,
      season: season == null ? null : SeasonArg.of(season),
      // Without these the modal built an image-type feed item: it showed a
      // still (the bundled placeholder, since the cover was dropped too) and
      // there was nothing to play.
      thumbnailUrl: ep.thumbnailUrl,
      videoUrl: ep.videoUrl,
    );
    if (!context.mounted) return;
    await showEpisodePlayerModal(context, sub);
  }

  /// This creator's seasons — Figma `304:9582`'s stacked-deck row, one per
  /// season rather than a single tile of a shared demo playlist.
  Widget _playlists(BuildContext context, CreatorRef creator) {
    final async = ref.watch(creatorSeasonsProvider(creator));

    return switch (async) {
      AsyncLoading() => const _EpisodeListSkeleton(),
      AsyncError(:final error) => LoadFailure(
        error: error,
        title: "We couldn't load these playlists",
        onRetry: () =>
            ref.read(creatorSeasonsProvider(creator).notifier).retry(),
      ),
      AsyncValue(:final value?) when value.isEmpty => const Padding(
        padding: EdgeInsets.only(top: SkifluxSpacing.space2xl),
        child: SkifluxEmptyState(
          icon: Icon(
            RemixIcons.play_list_2_fill,
            size: SkifluxEmptyState.iconSize,
            color: SkifluxColors.contentBrand,
          ),
          title: 'No playlists yet',
          message: 'This creator has not published a season so far.',
        ),
      ),
      AsyncValue(:final value?) => Column(
        children: [
          for (final pl in value) ...[
            _PlaylistTile(
              playlist: pl,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlaylistScreen(season: SeasonArg.of(pl)),
                ),
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
          ],
        ],
      ),
    };
  }

  /// Figma: Button Group Pill (198:14072) — Button component, size S.
  ///
  /// The pills used to be a fixed `['All','UI','Code','Motion','Brand']` that
  /// filtered nothing. They are now the distinct skillworlds this creator
  /// actually publishes in. One world means there is nothing to choose
  /// between, so the row is absent rather than showing a lone "All".
  Widget _pillGroup(CreatorRef creator) {
    final seasons = ref.watch(creatorSeasonsProvider(creator)).value;
    if (seasons == null) return const SizedBox.shrink();

    final worlds = <String>{
      for (final s in seasons)
        if (s.skillworld != null && s.skillworld!.isNotEmpty) s.skillworld!,
    }.toList(growable: false);
    if (worlds.length < 2) return const SizedBox.shrink();

    // A world outside the ten with authored art (the spec also has `code` and
    // `writing`) keeps its wire value as the label rather than disappearing.
    String labelOf(String value) =>
        SkillWorld.fromBackendValue(value)?.pillLabel ?? value;

    return Padding(
      padding: const EdgeInsets.only(bottom: SkifluxSpacing.spaceL),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SkifluxButton(
              label: 'All',
              size: SkifluxButtonSize.s,
              type: _world == null
                  ? SkifluxButtonType.primary
                  : SkifluxButtonType.secondary,
              onPressed: () => setState(() => _world = null),
            ),
            for (final w in worlds) ...[
              const SizedBox(width: SkifluxSpacing.spaceS),
              SkifluxButton(
                label: labelOf(w),
                size: SkifluxButtonSize.s,
                type: _world == w
                    ? SkifluxButtonType.primary
                    : SkifluxButtonType.secondary,
                onPressed: () => setState(() => _world = w),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Figma `304:9582` — stacked deck thumbnail + title + "creator · N Episodes".
class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({required this.playlist, required this.onTap});

  final Playlist playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 98,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlaylistDeck(
              width: 126,
              height: 98,
              episodeCount: playlist.episodeCount,
            ),
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
                      playlist.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SkifluxTypography.headingH10Bold.copyWith(
                        color: SkifluxColors.contentPrimary,
                      ),
                    ),
                    Text(
                      playlist.metaLine,
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
          // H8, matching the nav label above it. H5 rendered the creator's
          // name larger than any heading on the screen it sits in.
          profile.name,
          style: SkifluxTypography.headingH8Bold.copyWith(
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
    required this.title,
    this.duration = '',
    this.meta = '',
    this.progress,
    this.locked = false,
    this.coinPrice,
    this.thumbnailUrl,
    this.onTap,
  });

  final String episode;
  final String status;
  final Color statusColor;

  /// "20:00", or empty when the payload carried no `video_duration` — the
  /// corner pill then isn't drawn rather than claiming a length.
  final String duration;

  /// "22k views · 5 hrs ago", already trimmed to what is actually known.
  final String meta;

  final double? progress;
  final bool locked;
  final int? coinPrice;
  final String title;

  /// `Episode.thumbnail_url`. Null falls back to the bundled cover, which is
  /// what every row unconditionally showed before.
  final String? thumbnailUrl;

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
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: SkifluxSpacing.spaceXs),
                  Text(
                    meta,
                    style: SkifluxTypography.bodyP11Regular.copyWith(
                      color: SkifluxColors.contentTertiary,
                    ),
                  ),
                ],
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
            if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
              SkifluxNetworkImage(
                url: thumbnailUrl!,
                errorWidget: Image.asset(
                  'assets/home_video_cover.png',
                  fit: BoxFit.cover,
                ),
              )
            else
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
            if (duration.isNotEmpty)
              Positioned(
                bottom: SkifluxSpacing.spaceS,
                right: SkifluxSpacing.spaceS,
                child: _pill(duration, background: SkifluxColors.overlay50),
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

/// The profile's shape while `GET /creators/{id}` is in flight: avatar, name,
/// handle, the two action buttons, then the first rows of the Recent list.
///
/// A spinner here said nothing about what was coming; this holds the layout
/// steady so the header doesn't jump when the payload lands.
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkifluxSkeletonGroup(
      child: Padding(
        padding: EdgeInsets.all(SkifluxSpacing.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: SkifluxSkeleton.circle(size: SkifluxUnit.u64)),
            SizedBox(height: SkifluxSpacing.spaceS),
            Center(child: SkifluxSkeleton.text(width: 160, height: 20)),
            SizedBox(height: SkifluxSpacing.spaceXs),
            Center(child: SkifluxSkeleton.text(width: 96)),
            SizedBox(height: SkifluxSpacing.spaceS),
            Row(
              children: [
                Expanded(child: SkifluxSkeleton(height: 36)),
                SizedBox(width: SkifluxSpacing.spaceS),
                Expanded(child: SkifluxSkeleton(height: 36)),
              ],
            ),
            SizedBox(height: SkifluxSpacing.spaceL),
            SkifluxSkeleton(height: 36),
            SizedBox(height: SkifluxSpacing.spaceL),
            _EpisodeRowSkeleton(),
            SizedBox(height: SkifluxSpacing.spaceL),
            _EpisodeRowSkeleton(),
          ],
        ),
      ),
    );
  }
}

/// Recent / Playlists placeholder — the profile header is already on screen,
/// so only the list below it is standing in.
class _EpisodeListSkeleton extends StatelessWidget {
  const _EpisodeListSkeleton();

  /// Recent shows at most four rows; three is enough to fill the fold without
  /// implying a count the response has to match.
  static const _rows = 3;

  @override
  Widget build(BuildContext context) {
    return SkifluxSkeletonGroup(
      child: Column(
        children: [
          for (var i = 0; i < _rows; i++) ...[
            const _EpisodeRowSkeleton(),
            const SizedBox(height: SkifluxSpacing.spaceL),
          ],
        ],
      ),
    );
  }
}

/// Geometry matches [_EpisodeCard]: a 128×98 thumb beside three text lines.
class _EpisodeRowSkeleton extends StatelessWidget {
  const _EpisodeRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 98,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkifluxSkeleton(width: 128, height: 98, radius: SkifluxRadii.l),
          SizedBox(width: SkifluxSpacing.spaceS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkifluxSkeleton.text(width: 64),
                SizedBox(height: SkifluxSpacing.spaceXs),
                SkifluxSkeleton.text(width: double.infinity),
                SizedBox(height: SkifluxSpacing.spaceXs),
                SkifluxSkeleton.text(width: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
