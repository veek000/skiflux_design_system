import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../subscriptions/data/subscriptions_store.dart';

// Shared row for the profile library screens — Watch History (`1256:24224`),
// Downloads (`1256:24465`), Saved Videos (`1256:24572`), Liked Videos.
// 128×98 thumbnail (EP pill + duration pill), 2-line H10 title, creator
// avatar + name, a per-screen status line, and a per-screen trailing control.

class LibraryEpisodeRow extends ConsumerWidget {
  const LibraryEpisodeRow({
    super.key,
    required this.episode,
    required this.statusLine,
    required this.trailing,
    this.onTap,
  });

  final SubscriptionEpisode episode;

  /// Per-screen meta line, e.g. "72% watched · Today, 9:20 AM",
  /// "112 MB · SD 480p", "Saved 2 days ago".
  final String statusLine;

  /// Per-screen control: more-menu glyph, trash, bookmark, heart…
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creator = ref.watch(subscriptionsProvider).creatorOf(episode);
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
                      initials: creator.initials,
                    ),
                    const SizedBox(width: SkifluxSpacing.spaceXs),
                    Flexible(
                      child: Text(
                        creator.name,
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

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.episode});

  final SubscriptionEpisode episode;

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
            // TODO(backend, blocking): replace local placeholder asset with real CDN/backend episode thumbnail URL — expects: String (network URL)
            Image.asset(
              'assets/home_video_cover.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: SkifluxColors.magenta900),
            ),
            Positioned(
              top: SkifluxSpacing.spaceS,
              left: SkifluxSpacing.spaceS,
              child: _pill(
                episode.epTag,
                background: SkifluxColors.contentBrand,
              ),
            ),
            Positioned(
              bottom: SkifluxSpacing.spaceS,
              right: SkifluxSpacing.spaceS,
              child: _pill(
                episode.duration,
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
