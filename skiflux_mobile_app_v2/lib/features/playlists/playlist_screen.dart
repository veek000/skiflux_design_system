import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/share_sheet.dart';
import '../../shared/toast/skiflux_toast.dart';
import '../home/sheets/episode_unlock_sheet.dart';
import '../subscriptions/data/subscriptions_store.dart';
import '../subscriptions/subscriptions_screen.dart';
import 'data/playlists_store.dart';
import 'playlist_description_sheet.dart';

// Figma: **Home & In-app Flow 05** (`198:14183`) — playlist detail page.

class PlaylistScreen extends ConsumerStatefulWidget {
  const PlaylistScreen({super.key});

  @override
  ConsumerState<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends ConsumerState<PlaylistScreen> {
  bool _liked = false;
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final pl = ref.watch(playlistsProvider).defaultPlaylist;
    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Playlist',
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
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Hero cover with gradient
          SizedBox(
            height: 220,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  pl.coverAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: SkifluxColors.backgroundBrand,
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0xCC000000),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pl.title,
                  style: SkifluxTypography.headingH7Bold.copyWith(
                    color: SkifluxColors.contentPrimary,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceXs),
                Text(
                  pl.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SkifluxTypography.bodyP10Regular.copyWith(
                    color: SkifluxColors.contentTertiary,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceXs),
                GestureDetector(
                  onTap: () => showPlaylistDescriptionSheet(
                    context,
                    playlist: pl,
                  ),
                  child: Text(
                    'View Full Description',
                    style: SkifluxTypography.bodyP10Semibold.copyWith(
                      color: SkifluxColors.contentLink,
                    ),
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceS),
                Text(
                  pl.detailMeta,
                  style: SkifluxTypography.bodyP10Regular.copyWith(
                    color: SkifluxColors.contentTertiary,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceL),
                // Creator row
                Row(
                  children: [
                    const SkifluxAvatar(
                      style: SkifluxAvatarStyle.initial,
                      size: 40,
                      initials: 'A',
                    ),
                    const SizedBox(width: SkifluxSpacing.spaceS),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pl.creatorName,
                            style: SkifluxTypography.headingH10Bold.copyWith(
                              color: SkifluxColors.contentPrimary,
                            ),
                          ),
                          Text(
                            '@${pl.creatorUsername}',
                            style: SkifluxTypography.bodyP11Regular.copyWith(
                              color: SkifluxColors.contentTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: SkifluxColors.backgroundBrand,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          SkifluxToast.success(context, 'Following creator');
                        },
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            RemixIcons.add_fill,
                            color: SkifluxColors.contentPrimaryInverse,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SkifluxSpacing.spaceL),
                // Action rail
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Action(
                      icon: RemixIcons.heart_3_fill,
                      label: '120',
                      active: _liked,
                      activeColor: SkifluxColors.contentNegative,
                      onTap: () => setState(() => _liked = !_liked),
                    ),
                    _Action(
                      icon: RemixIcons.chat_3_fill,
                      label: '120',
                      onTap: () {},
                    ),
                    _Action(
                      icon: RemixIcons.bookmark_fill,
                      label: 'Save',
                      active: _saved,
                      activeColor: SkifluxColors.contentBrand,
                      onTap: () => setState(() => _saved = !_saved),
                    ),
                    _Action(
                      icon: RemixIcons.share_forward_fill,
                      label: 'Share',
                      onTap: () => showShareSheet(context),
                    ),
                  ],
                ),
                const SizedBox(height: SkifluxSpacing.spaceXl),
                for (final ep in pl.episodes) ...[
                  _PlaylistEpisodeRow(
                    episode: ep,
                    onTap: () => _openEpisode(context, ep, pl),
                  ),
                  const SizedBox(height: SkifluxSpacing.spaceL),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEpisode(
    BuildContext context,
    PlaylistEpisode ep,
    Playlist pl,
  ) async {
    if (ep.isLocked) {
      await showEpisodeUnlockSheet(context, episodeId: ep.id);
      return;
    }
    final sub = SubscriptionEpisode(
      epNumber: ep.number,
      title: ep.title,
      creatorUsername: pl.creatorUsername,
      duration: ep.duration,
      views: '22k',
      postedAgo: '5 hrs ago',
      watchProgress: ep.state == PlaylistEpisodeState.completed ? 1 : 0.15,
    );
    if (!context.mounted) return;
    await showEpisodePlayerModal(context, sub);
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    this.onTap,
    this.active = false,
    this.activeColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? (activeColor ?? SkifluxColors.contentBrand)
        : SkifluxColors.contentPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: SkifluxRadii.borderM,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SkifluxSpacing.spaceM,
          vertical: SkifluxSpacing.spaceS,
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: SkifluxSpacing.space2xs),
            Text(
              label,
              style: SkifluxTypography.uiBadgeTagSmall.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma episode row on playlist detail — thumb 128×98, status, play / coins.
class _PlaylistEpisodeRow extends StatelessWidget {
  const _PlaylistEpisodeRow({required this.episode, required this.onTap});

  final PlaylistEpisode episode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = episode.isLocked;
    final statusLabel = switch (episode.state) {
      PlaylistEpisodeState.completed => 'Completed',
      PlaylistEpisodeState.unlocked => 'Unlocked',
      PlaylistEpisodeState.locked => 'Locked',
    };
    final statusColor = switch (episode.state) {
      PlaylistEpisodeState.completed => SkifluxColors.contentPositive,
      PlaylistEpisodeState.unlocked => SkifluxColors.contentNotice,
      PlaylistEpisodeState.locked => SkifluxColors.contentTertiary,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: SkifluxRadii.borderL,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: SkifluxRadii.borderL,
            child: SizedBox(
              width: 128,
              height: 98,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/home_video_cover.png',
                    fit: BoxFit.cover,
                  ),
                  if (locked) ...[
                    const ColoredBox(color: SkifluxColors.overlay50),
                    const Center(
                      child: Icon(
                        RemixIcons.lock_2_fill,
                        color: SkifluxColors.contentPrimaryInverse,
                      ),
                    ),
                  ],
                  Positioned(
                    top: SkifluxSpacing.spaceS,
                    left: SkifluxSpacing.spaceS,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SkifluxSpacing.spaceS,
                        vertical: SkifluxSpacing.space2xs,
                      ),
                      decoration: BoxDecoration(
                        color: SkifluxColors.contentBrand,
                        borderRadius: SkifluxRadii.borderX,
                      ),
                      child: Text(
                        episode.epTag,
                        style: SkifluxTypography.bodyP11Semibold.copyWith(
                          color: SkifluxColors.contentPrimaryInverse,
                        ),
                      ),
                    ),
                  ),
                  if (!locked)
                    Positioned(
                      bottom: SkifluxSpacing.spaceS,
                      right: SkifluxSpacing.spaceS,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SkifluxSpacing.spaceS,
                          vertical: SkifluxSpacing.space2xs,
                        ),
                        decoration: BoxDecoration(
                          color: SkifluxColors.overlay50,
                          borderRadius: SkifluxRadii.borderX,
                        ),
                        child: Text(
                          episode.duration,
                          style: SkifluxTypography.bodyP11Semibold.copyWith(
                            color: SkifluxColors.contentPrimaryInverse,
                          ),
                        ),
                      ),
                    ),
                  if (episode.state == PlaylistEpisodeState.completed)
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SizedBox(
                        height: SkifluxSpacing.spaceXs,
                        child: ColoredBox(
                          color: SkifluxColors.contentBrand,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceXs),
                Text(
                  episode.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
          if (locked)
            Container(
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
                    '${episode.coinCost}',
                    style: SkifluxTypography.uiBadgeTagMedium.copyWith(
                      color: SkifluxColors.contentNoticeBold,
                    ),
                  ),
                ],
              ),
            )
          else
            const Icon(
              RemixIcons.play_circle_fill,
              size: SkifluxIcons.sizeM,
              color: SkifluxColors.contentDisabled,
            ),
        ],
      ),
    );
  }
}
