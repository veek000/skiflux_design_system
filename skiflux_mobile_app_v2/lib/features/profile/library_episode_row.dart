// Shared row for the profile library screens — Watch History (`1256:24224`),
// Downloads (`1256:24465`), Saved Videos (`1256:24572`), Liked Videos.
// 128×98 thumbnail (EP pill + duration pill), 2-line H10 title, creator
// avatar + name, a per-screen status line, and a per-screen trailing control.

import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'data/library_episode.dart';

class LibraryEpisodeRow extends StatelessWidget {
  const LibraryEpisodeRow({
    super.key,
    required this.episode,
    required this.statusLine,
    required this.trailing,
    this.onTap,
  });

  final LibraryEpisode episode;

  /// Per-screen meta line, e.g. "72% watched · Today, 9:20 AM",
  /// "112 MB · SD 480p", "1.2K views".
  final String statusLine;

  /// Per-screen control: more-menu glyph, trash, bookmark, heart…
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: SkifluxRadii.borderL,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Thumbnail(episode: episode),
          const SizedBox(width: SkifluxSpacing.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      size: SkifluxSpacing.spaceL,
                      initials: episode.creatorInitials,
                    ),
                    const SizedBox(width: SkifluxSpacing.spaceXs),
                    Flexible(
                      child: Text(
                        episode.creatorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SkifluxTypography.bodyP11Regular.copyWith(
                          color: SkifluxColors.contentTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SkifluxSpacing.spaceXs),
                Text(
                  statusLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SkifluxTypography.bodyP11Regular.copyWith(
                    color: SkifluxColors.contentTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          trailing,
        ],
      ),
    );
  }
}

/// The row's silhouette while the list is in flight — same 128×98 block and
/// three text lines, so nothing shifts when the real rows arrive.
class LibraryEpisodeRowSkeleton extends StatelessWidget {
  const LibraryEpisodeRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkifluxSkeletonGroup(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkifluxSkeleton(width: 128, height: 98, radius: SkifluxRadii.l),
          SizedBox(width: SkifluxSpacing.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkifluxSkeleton.text(height: SkifluxSpacing.spaceL),
                SizedBox(height: SkifluxSpacing.spaceS),
                SkifluxSkeleton.text(width: 120),
                SizedBox(height: SkifluxSpacing.spaceS),
                SkifluxSkeleton.text(width: 80, height: SkifluxSpacing.spaceS),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A list of [LibraryEpisodeRowSkeleton]s laid out like the real list.
class LibraryListSkeleton extends StatelessWidget {
  const LibraryListSkeleton({super.key, this.rows = 5});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        SkifluxSpacing.spaceL,
        0,
        SkifluxSpacing.spaceL,
        SkifluxSpacing.spaceL,
      ),
      itemCount: rows,
      separatorBuilder: (_, _) => const SizedBox(height: SkifluxSpacing.spaceL),
      itemBuilder: (_, _) => const LibraryEpisodeRowSkeleton(),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.episode});

  final LibraryEpisode episode;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: SkifluxRadii.borderL,
      child: SizedBox(
        width: 128,
        height: 98,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _cover(),
            Positioned(
              top: SkifluxSpacing.spaceS,
              left: SkifluxSpacing.spaceS,
              child: _pill(
                episode.epTag,
                background: SkifluxColors.contentBrand,
              ),
            ),
            if (episode.durationLabel.isNotEmpty)
              Positioned(
                bottom: SkifluxSpacing.spaceS,
                right: SkifluxSpacing.spaceS,
                child: _pill(
                  episode.durationLabel,
                  background: SkifluxColors.overlay50,
                ),
              ),
            // Brand watch-progress strip along the bottom edge (Watch
            // History rows show partial progress in the frame).
            if (episode.watchProgress > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SizedBox(
                  height: SkifluxSpacing.spaceXs,
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: ColoredBox(
                          color: SkifluxColors.backgroundSelected,
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: episode.watchProgress.clamp(0, 1),
                        heightFactor: 1,
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

  /// The CDN thumbnail, with a shimmering block while it decodes. An episode
  /// with no `thumbnail_url` gets the block permanently rather than a stock
  /// image that would imply the wrong content.
  Widget _cover() {
    final url = episode.thumbnailUrl;
    if (url == null || url.isEmpty) {
      return const ColoredBox(color: SkifluxColors.backgroundDisabled);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const SkifluxSkeleton(radius: 0),
      errorBuilder: (_, _, _) =>
          const ColoredBox(color: SkifluxColors.backgroundDisabled),
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
}
