import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../features/home/sheets/comments_sheet.dart';
import '../../features/home/sheets/more_menu_sheet.dart';
import '../../features/playlists/playlist_menu_sheet.dart';
import '../sheets/share_sheet.dart';

/// Figma: video player card (`325:14149`) — cover, progress bar, EP chip,
/// title/description, action rail (like/comment/save/share/more).
///
/// Extracted from the home feed so the subscriptions episode modal
/// (Subscription Flow 02, `1256:29748`) can present the same player.
class VideoFeedCard extends StatelessWidget {
  const VideoFeedCard({
    super.key,
    this.epTag = 'EP 01',
    this.title = 'Code',
    this.description = 'Video Description',
    this.borderRadius,
  });

  final String epTag;
  final String title;
  final String description;

  /// Corner rounding — defaults to `Radius/L`; the subscriptions player
  /// sheet passes [BorderRadius.zero] for a full-bleed video.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? SkifluxRadii.borderL,
      child: ColoredBox(
        // Figma card base fill: content/brand-inactive (325:14149).
        color: SkifluxColors.contentBrandInactive,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Cover image from Figma node 325:14150
            Image.asset(
              'assets/home_video_raw1.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/home_video_cover.png',
                fit: BoxFit.cover,
              ),
            ),
            // Bottom gradient for legibility (Figma linear overlay → black).
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0x00000000),
                    Color(0xFF000000),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Progress bar — Figma Video Progress (325:14179)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: SkifluxRadii.borderPill,
                child: const SizedBox(
                  height: SkifluxSpacing.spaceXs,
                  child: Stack(
                    children: [
                      ColoredBox(color: SkifluxColors.backgroundSelected),
                      FractionallySizedBox(
                        widthFactor: 100 / 361,
                        child: ColoredBox(
                          color: SkifluxColors.contentBrand,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom content + action rail
            Positioned(
              left: SkifluxSpacing.spaceM,
              right: SkifluxSpacing.spaceM,
              bottom: SkifluxSpacing.spaceM,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // EP chip → playlist menu sheet (1256:27214).
                        Material(
                          color: SkifluxColors.backgroundPrimaryBrand,
                          borderRadius: SkifluxRadii.borderPill,
                          child: InkWell(
                            onTap: () => showPlaylistMenuSheet(context),
                            borderRadius: SkifluxRadii.borderPill,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: SkifluxSpacing.spaceS,
                                right: SkifluxSpacing.spaceXs,
                                top: SkifluxSpacing.spaceXs,
                                bottom: SkifluxSpacing.spaceXs,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    epTag,
                                    style: SkifluxTypography.uiBadgeTagSmall
                                        .copyWith(
                                      color: SkifluxColors.contentBrand,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: SkifluxSpacing.space2xs,
                                  ),
                                  const Icon(
                                    RemixIcons.arrow_right_s_line,
                                    size: SkifluxSpacing.spaceM,
                                    color: SkifluxColors.contentBrand,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: SkifluxSpacing.spaceS),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SkifluxTypography.headingH9Bold.copyWith(
                            color: SkifluxColors.contentPrimaryInverse,
                          ),
                        ),
                        const SizedBox(height: SkifluxSpacing.space2xs),
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SkifluxTypography.bodyP10Regular.copyWith(
                            color: SkifluxColors.contentTertiaryInverse,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: SkifluxSpacing.spaceS),
                  const _ActionRail(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRail extends StatelessWidget {
  const _ActionRail();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _LikeButton(initialCount: 120),
        const SizedBox(height: SkifluxSpacing.spaceS),
        _ActionItem(
          icon: RemixIcons.chat_3_fill,
          count: '120',
          onTap: () => showCommentsSheet(context),
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        const _ActionItem(icon: RemixIcons.bookmark_fill, count: '120'),
        const SizedBox(height: SkifluxSpacing.spaceS),
        _ActionItem(
          icon: RemixIcons.share_forward_fill,
          count: '120',
          onTap: () => showShareSheet(context),
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        GestureDetector(
          onTap: () => showMoreMenuSheet(context),
          child: const Icon(
            RemixIcons.more_fill,
            size: SkifluxUnit.u32,
            color: SkifluxColors.contentPrimaryInverse,
          ),
        ),
      ],
    );
  }
}

/// Like control — heart pops (elastic scale) and fills red when liked.
class _LikeButton extends StatefulWidget {
  const _LikeButton({required this.initialCount});

  final int initialCount;

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 35),
    TweenSequenceItem(
      tween: Tween(begin: 1.35, end: 1.0)
          .chain(CurveTween(curve: Curves.elasticOut)),
      weight: 65,
    ),
  ]).animate(_controller);

  bool _liked = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _liked = !_liked);
    if (_liked) {
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.initialCount + (_liked ? 1 : 0);
    return GestureDetector(
      onTap: _toggle,
      child: Column(
        children: [
          // Isolate the animating heart so the elastic scale doesn't force
          // the rest of the card (and screen) to re-rasterize every frame.
          RepaintBoundary(
            child: ScaleTransition(
              scale: _scale,
              child: Icon(
                RemixIcons.heart_3_fill,
                size: SkifluxUnit.u32,
                color: _liked
                    ? SkifluxColors.contentNegative
                    : SkifluxColors.contentPrimaryInverse,
              ),
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceXs),
          Text(
            '$count',
            style: SkifluxTypography.uiBadgeTagSmall.copyWith(
              color: SkifluxColors.contentPrimaryInverse,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({required this.icon, required this.count, this.onTap});

  final IconData icon;
  final String count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            size: SkifluxUnit.u32,
            color: SkifluxColors.contentPrimaryInverse,
          ),
          const SizedBox(height: SkifluxSpacing.spaceXs),
          Text(
            count,
            style: SkifluxTypography.uiBadgeTagSmall.copyWith(
              color: SkifluxColors.contentPrimaryInverse,
            ),
          ),
        ],
      ),
    );
  }
}
