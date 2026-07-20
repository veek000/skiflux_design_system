import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'data/playlists_store.dart';

/// Episode row shared by the playlist detail page (`198:14183` /
/// `827:35445`) and the playlist menu sheet (`1256:27214`):
/// 128×98 thumb (EP chip, duration chip, 4px progress bar; locked = blur +
/// centered lock), status + title + views meta, trailing play circle or
/// coin pill. [playing] renders the `1256:27298` variant — brand100 row
/// fill, "Playing EP 0X" status, partial progress, no trailing control.
class PlaylistEpisodeRow extends StatelessWidget {
  const PlaylistEpisodeRow({
    super.key,
    required this.episode,
    this.onTap,
    this.playing = false,
  });

  final PlaylistEpisode episode;
  final VoidCallback? onTap;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final locked = episode.isLocked;
    final statusLabel = playing
        ? 'Playing ${episode.epTag}'
        : switch (episode.state) {
            PlaylistEpisodeState.completed => 'Completed',
            PlaylistEpisodeState.unlocked => 'Unlocked',
            PlaylistEpisodeState.locked => 'Locked',
          };
    final statusColor = playing
        ? SkifluxColors.contentBrand
        : switch (episode.state) {
            PlaylistEpisodeState.completed => SkifluxColors.contentPositive,
            PlaylistEpisodeState.unlocked => SkifluxColors.contentNotice,
            PlaylistEpisodeState.locked => SkifluxColors.contentTertiary,
          };

    final row = Row(
      children: [
        _Thumb(
          episode: episode,
          // Figma: playing row shows a partial fill (90.6/128); completed
          // and unlocked rows show the full bar (827:35454 / 827:35473).
          progress: locked ? null : (playing ? 0.71 : 1.0),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SkifluxSpacing.spaceS,
            ),
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
        ),
        // Trailing control sits centered in a 48px slot (Figma "Avatar").
        if (!playing)
          SizedBox(
            width: SkifluxUnit.u48,
            height: SkifluxUnit.u48,
            child: Center(
              child: locked ? _coinPill() : _playIcon(),
            ),
          ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: playing
          ? Container(
              decoration: BoxDecoration(
                color: SkifluxColors.backgroundSelected,
                borderRadius: SkifluxRadii.borderL,
              ),
              child: row,
            )
          : row,
    );
  }

  Widget _playIcon() {
    return const Icon(
      RemixIcons.play_circle_fill,
      size: SkifluxIcons.sizeM,
      color: SkifluxColors.contentDisabled,
    );
  }

  Widget _coinPill() {
    // Figma `827:35499` — notice-subtle pill: coin 16 + price Creato Bold 12.
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
            '${episode.coinCost}',
            style: SkifluxTypography.uiButtonSmall.copyWith(
              color: SkifluxColors.contentNoticeBold,
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.episode, this.progress});

  final PlaylistEpisode episode;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final locked = episode.isLocked;
    Widget image = Image.asset(
      'assets/home_video_cover.png',
      fit: BoxFit.cover,
    );
    if (locked) {
      // Figma `827:35485`: 5px backdrop blur + 50% black over the cover.
      image = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: image,
      );
    }
    return ClipRRect(
      borderRadius: SkifluxRadii.borderL,
      child: SizedBox(
        width: 128,
        height: 98,
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
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
            // EP chip — brand pill top-left.
            Positioned(
              top: SkifluxSpacing.spaceS,
              left: SkifluxSpacing.spaceS,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SkifluxSpacing.spaceS,
                  vertical: SkifluxSpacing.spaceXs,
                ),
                decoration: BoxDecoration(
                  color: SkifluxColors.contentBrand,
                  borderRadius: SkifluxRadii.borderX,
                ),
                child: Text(
                  episode.epTag,
                  style: SkifluxTypography.bodyP11Semibold.copyWith(
                    color: SkifluxColors.contentPrimaryInverse,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            if (!locked)
              // Duration chip — overlay50 bottom-right.
              Positioned(
                bottom: SkifluxSpacing.spaceS,
                right: SkifluxSpacing.spaceS,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SkifluxSpacing.spaceXs,
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
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            if (progress != null)
              // 4px video-progress bar hugging the bottom edge.
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
}
