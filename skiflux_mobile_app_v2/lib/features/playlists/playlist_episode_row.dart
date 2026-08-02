import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/widgets/network_image.dart';
import 'data/playlists_store.dart';

/// Episode row shared by the playlist detail page (`198:14183` /
/// `827:35445`) and the playlist menu sheet (`1256:27214`):
/// 128×98 thumb (EP chip, duration chip, 4px progress bar; locked = blur +
/// centered lock), status + title + views meta, trailing play circle or
/// coin pill. [playing] renders the `1256:27298` variant — brand100 row
/// fill, "Playing EP 0X" status, no trailing control.
class PlaylistEpisodeRow extends StatelessWidget {
  const PlaylistEpisodeRow({
    super.key,
    required this.episode,
    this.onTap,
    this.playing = false,
    this.progress,
  });

  final PlaylistEpisode episode;
  final VoidCallback? onTap;
  final bool playing;

  /// Watch progress, 0–1, from a real player clock. Null draws no bar.
  ///
  /// Only the caller that owns the player can supply this. Every unlocked row
  /// used to render a *full* bar, and the playing row a fixed `0.71` — both
  /// claimed a watch position the user had never reached.
  final double? progress;

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
          // Whatever the player actually reports, or nothing. A bar drawn from
          // a made-up number is worse than no bar: it tells the user they left
          // off somewhere they never were.
          progress: progress,
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
                // Real views and age, or no line at all. This was hardcoded
                // "22k views · 5 hrs ago" on every row in every season.
                if (episode.metaLine.isNotEmpty) ...[
                  const SizedBox(height: SkifluxSpacing.spaceXs),
                  Text(
                    episode.metaLine,
                    style: SkifluxTypography.bodyP11Regular.copyWith(
                      color: SkifluxColors.contentTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Trailing control sits centered in a 48px slot (Figma "Avatar").
        // 48 is the floor, not the width: the coin pill is as wide as its
        // price, and a three-figure cost overflowed a fixed box — which
        // clipped the number the row exists to show.
        if (!playing)
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: SkifluxUnit.u48,
              minHeight: SkifluxUnit.u48,
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
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
    const fallback = 'assets/home_video_cover.png';
    final thumbnailUrl = episode.thumbnailUrl;
    // `Episode.thumbnail_url` is required by the schema, so the asset is a
    // decode/404 fallback rather than the normal path. Every row rendering the
    // same stock cover was the giveaway that it was never parsed.
    Widget image = (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
        ? SkifluxNetworkImage(
            url: thumbnailUrl,
            errorWidget: Image.asset(fallback, fit: BoxFit.cover),
          )
        : Image.asset(fallback, fit: BoxFit.cover);
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
}
