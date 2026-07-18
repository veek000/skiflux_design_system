import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/share_sheet.dart';
import '../home/sheets/episode_unlock_sheet.dart';
import '../home/sheets/notify_settings_sheet.dart';
import '../playlists/data/playlists_store.dart';
import '../playlists/playlist_screen.dart';
import '../subscriptions/data/subscriptions_store.dart';
import '../subscriptions/subscriptions_screen.dart';

/// Figma: **Home & In-app Flow 07** (`198:14048`) — Profile screen.
///
/// Top nav, creator header (Subscribe / Notify), Recent | Playlists tabs,
/// pill filter group, and episode cards (Completed / Unlocked / Locked).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tabIndex = 0;
  int _pillIndex = 0;
  bool _subscribed = false;
  NotifyPreference _notify = NotifyPreference.personalized;

  static const _pills = ['All', 'UI', 'Code', 'Motion', 'Brand'];

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
        child: ListView(
          padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
          children: [
            _ProfileHeader(
              subscribed: _subscribed,
              onSubscribe: () {
                setState(() => _subscribed = !_subscribed);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _subscribed
                          ? 'Subscribed to Amara Design'
                          : 'Unsubscribed',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              onNotify: () async {
                final messenger = ScaffoldMessenger.of(context);
                final next = await showNotifySettingsSheet(
                  context,
                  current: _notify,
                );
                if (!mounted || next == null) return;
                setState(() => _notify = next);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('${next.toastTitle}\n${next.toastBody}'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: next == NotifyPreference.none
                        ? SkifluxColors.contentSecondary
                        : SkifluxColors.backgroundBrand,
                  ),
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
        ),
      ),
    );
  }

  List<Widget> _recentEpisodes(BuildContext context) {
    final eps = PlaylistsStore.instance.defaultPlaylist.episodes.take(4);
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
              watchProgress:
                  ep.state == PlaylistEpisodeState.completed ? 1 : 0.2,
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

  /// Figma Home Flow 06 playlist row: stacked cover (image) + count chip.
  Widget _playlistTile(BuildContext context) {
    final pl = PlaylistsStore.instance.defaultPlaylist;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PlaylistScreen()),
        ),
        borderRadius: SkifluxRadii.borderL,
        child: Row(
          children: [
            SizedBox(
              width: 132,
              height: 132,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Back card peeks (offset) — uses cover image tinted.
                  Positioned(
                    left: 6,
                    top: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          SkifluxColors.magenta200.withValues(alpha: 0.85),
                          BlendMode.srcATop,
                        ),
                        child: Image.asset(
                          pl.coverAsset,
                          width: 114,
                          height: 114,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  // Front card
                  Positioned(
                    left: 0,
                    top: 5,
                    child: ClipRRect(
                      borderRadius: SkifluxRadii.borderL,
                      child: SizedBox(
                        width: 126,
                        height: 126,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              pl.coverAsset,
                              fit: BoxFit.cover,
                            ),
                            const ColoredBox(
                              color: Color(0x66000000),
                            ),
                            Positioned(
                              right: SkifluxSpacing.spaceM,
                              bottom: SkifluxSpacing.spaceM,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: SkifluxSpacing.spaceS,
                                  vertical: SkifluxSpacing.spaceXs,
                                ),
                                decoration: BoxDecoration(
                                  color: SkifluxColors.backgroundPrimaryBrand,
                                  borderRadius: SkifluxRadii.borderX,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      RemixIcons.play_list_2_line,
                                      size: 12,
                                      color: SkifluxColors.contentBrand,
                                    ),
                                    const SizedBox(
                                      width: SkifluxSpacing.space2xs,
                                    ),
                                    Text(
                                      '${pl.episodeCount}',
                                      style: SkifluxTypography.uiBadgeTagSmall
                                          .copyWith(
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
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: SkifluxSpacing.spaceS),
            Expanded(
              child: SizedBox(
                height: 126,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pl.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: SkifluxTypography.headingH9Bold.copyWith(
                        color: SkifluxColors.contentPrimary,
                        height: 24 / 18,
                      ),
                    ),
                    Text(
                      pl.viewsLabel,
                      style: SkifluxTypography.bodyP10Regular.copyWith(
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
    required this.subscribed,
    required this.onSubscribe,
    required this.onNotify,
  });

  final bool subscribed;
  final VoidCallback onSubscribe;
  final VoidCallback onNotify;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SkifluxAvatar(
          style: SkifluxAvatarStyle.initial,
          size: SkifluxUnit.u64,
          initials: 'A',
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        Text(
          'Amara Design',
          style: SkifluxTypography.headingH8Bold.copyWith(
            color: SkifluxColors.contentPrimary,
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceXs),
        Text(
          '@amara',
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
              child: _pill(
                episode,
                background: SkifluxColors.contentBrand,
              ),
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
                      const ColoredBox(
                        color: SkifluxColors.backgroundSelected,
                      ),
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
