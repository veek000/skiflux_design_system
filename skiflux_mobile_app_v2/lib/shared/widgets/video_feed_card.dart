import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';
import 'package:video_player/video_player.dart';

import '../../features/home/data/home_feed_store.dart';
import '../../features/home/sheets/comments_sheet.dart';
import '../../features/home/sheets/more_menu_sheet.dart';
import '../../features/playlists/playlist_menu_sheet.dart';
import '../sheets/description_sheet.dart';
import '../sheets/share_sheet.dart';

/// Figma: video player card (`325:14149`) — media, progress bar, EP chip,
/// title/description, action rail (like/comment/save/share/more).
///
/// Supports [FeedContentType.video] and [FeedContentType.image]:
/// - **Video** with [HomeFeedItem.videoUrl]: real [VideoPlayerController]
///   playback; top purple progress bar tracks `position / duration`.
/// - **Image** (or video without a URL): static cover only — no controller,
///   no progress bar.
///
/// Chrome (EP chip, title, description, rail) is identical for both types.
class VideoFeedCard extends StatefulWidget {
  const VideoFeedCard({
    super.key,
    this.item,
    this.epTag = 'EP 01',
    this.title = 'Code',
    this.description = 'Video Description',
    this.contentType = FeedContentType.video,
    this.coverAsset = 'assets/home_video_raw1.png',
    this.videoUrl,
    this.borderRadius,
    /// When false (e.g. off-screen PageView page), playback is paused.
    this.isActive = true,
  });

  /// Preferred: full feed model. When null, legacy named fields are used
  /// (subscriptions episode modal still passes ep/title/description).
  final HomeFeedItem? item;

  final String epTag;
  final String title;
  final String description;
  final FeedContentType contentType;
  final String coverAsset;
  final String? videoUrl;

  /// Corner rounding — defaults to `Radius/L`; the subscriptions player
  /// sheet passes [BorderRadius.zero] for a full-bleed video.
  final BorderRadius? borderRadius;

  /// Parent sets this from the vertical PageView index so only the visible
  /// card plays audio-less video.
  final bool isActive;

  @override
  State<VideoFeedCard> createState() => _VideoFeedCardState();
}

class _VideoFeedCardState extends State<VideoFeedCard> {
  VideoPlayerController? _controller;
  var _ready = false;
  var _initFailed = false;

  HomeFeedItem get _item =>
      widget.item ??
      HomeFeedItem(
        type: widget.contentType,
        epTag: widget.epTag,
        title: widget.title,
        description: widget.description,
        coverAsset: widget.coverAsset,
        videoUrl: widget.videoUrl,
        creatorName: '',
        creatorUsername: '',
        creatorInitials: '',
      );

  @override
  void initState() {
    super.initState();
    _startControllerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant VideoFeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldUrl = oldWidget.item?.videoUrl ?? oldWidget.videoUrl;
    final newUrl = _item.videoUrl;
    final oldType = oldWidget.item?.type ?? oldWidget.contentType;
    final newType = _item.type;
    if (oldUrl != newUrl || oldType != newType) {
      _disposeController();
      _startControllerIfNeeded();
      return;
    }
    if (oldWidget.isActive != widget.isActive) {
      _syncPlayPause();
    }
  }

  Future<void> _startControllerIfNeeded() async {
    if (!_item.hasPlayableVideo) return;
    final url = _item.videoUrl!;
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;
    controller.addListener(_onControllerTick);
    try {
      await controller.initialize();
      if (!mounted || _controller != controller) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0); // feed autoplay is muted
      setState(() => _ready = true);
      _syncPlayPause();
    } catch (e) {
      // Missing plugin under tests, network failure, bad URL — cover stays.
      debugPrint('VideoFeedCard: init failed for $url → $e');
      if (!mounted) return;
      await controller.dispose();
      if (_controller == controller) {
        _controller = null;
        setState(() {
          _ready = false;
          _initFailed = true;
        });
      }
    }
  }

  void _onControllerTick() {
    if (!mounted) return;
    // Rebuild for progress bar; VideoPlayer also paints via its own Texture.
    setState(() {});
  }

  void _syncPlayPause() {
    final c = _controller;
    if (c == null || !_ready) return;
    if (widget.isActive) {
      if (!c.value.isPlaying) c.play();
    } else {
      if (c.value.isPlaying) c.pause();
    }
  }

  Future<void> _disposeController() async {
    final c = _controller;
    _controller = null;
    _ready = false;
    _initFailed = false;
    if (c == null) return;
    c.removeListener(_onControllerTick);
    await c.dispose();
  }

  @override
  void dispose() {
    final c = _controller;
    _controller = null;
    c?.removeListener(_onControllerTick);
    c?.dispose();
    super.dispose();
  }

  /// 0–1 from real controller clock; null when this card is not a playing video.
  double? get _progress {
    if (!_item.isVideo) return null;
    // Video type without a stream still shows a zeroed track only if we had
    // decorative progress before — product: progress only when playable.
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      // Keep the Figma track visible for video-type items while buffering /
      // after init failure (fill at 0) so the chrome matches design.
      return 0;
    }
    return videoProgressFraction(c.value.position, c.value.duration);
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final progress = _progress;
    final showVideo = _ready && _controller != null && !_initFailed;

    return ClipRRect(
      borderRadius: widget.borderRadius ?? SkifluxRadii.borderL,
      child: ColoredBox(
        // Figma card base fill: content/brand-inactive (325:14149).
        color: SkifluxColors.contentBrandInactive,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Cover: CDN thumbnail when the feed provides one, else local asset.
            if (item.hasNetworkCover)
              Image.network(
                item.coverUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Image.asset(
                  item.coverAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Image.asset(
                    'assets/home_video_cover.png',
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Image.asset(
                item.coverAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Image.asset('assets/home_video_cover.png', fit: BoxFit.cover),
              ),
            if (showVideo)
              FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
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
            if (progress != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _VideoProgressBar(progress: progress),
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
                        Material(
                          color: SkifluxColors.backgroundPrimaryBrand,
                          borderRadius: SkifluxRadii.borderPill,
                          child: InkWell(
                            onTap: () => showPlaylistMenuSheet(
                              context,
                              playingEpisodeNumber: int.tryParse(
                                item.epTag.replaceAll(RegExp(r'[^0-9]'), ''),
                              ),
                            ),
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
                                    item.epTag,
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
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SkifluxTypography.headingH9Bold.copyWith(
                            color: SkifluxColors.contentPrimaryInverse,
                          ),
                        ),
                        const SizedBox(height: SkifluxSpacing.space2xs),
                        _FeedDescription(text: item.description),
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

/// Figma `325:14179` Video Progress — top edge, full width of the card,
/// height `Space/XS` (4), track `backgroundSelected`, fill `contentBrand`
/// (`brand500` / #5610AB). Left-to-right elapsed fill only (no time labels).
class _VideoProgressBar extends StatelessWidget {
  const _VideoProgressBar({required this.progress});

  /// 0.0–1.0 elapsed fraction from [videoProgressFraction].
  final double progress;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: SkifluxRadii.borderPill,
      child: SizedBox(
        height: SkifluxSpacing.spaceXs, // 4px — matches Figma h-[4px]
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: SkifluxColors.backgroundSelected),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clamped,
              child: const ColoredBox(color: SkifluxColors.contentBrand),
            ),
          ],
        ),
      ),
    );
  }
}

/// Description clamped to 2 lines; "View More" opens [showDescriptionSheet]
/// when the full text overflows.
class _FeedDescription extends StatelessWidget {
  const _FeedDescription({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final style = SkifluxTypography.bodyP10Regular.copyWith(
      color: SkifluxColors.contentTertiaryInverse,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 2,
          textDirection: TextDirection.ltr,
          ellipsis: '…',
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
            if (overflows) ...[
              const SizedBox(height: SkifluxSpacing.space2xs),
              GestureDetector(
                onTap: () => showDescriptionSheet(
                  context,
                  description: text,
                ),
                child: Text(
                  'View More',
                  style: SkifluxTypography.bodyP10Regular.copyWith(
                    color: SkifluxColors.contentLink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        );
      },
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
      tween: Tween(
        begin: 1.35,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.elasticOut)),
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
