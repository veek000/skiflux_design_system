import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';
import 'package:video_player/video_player.dart';

import '../../features/home/data/episodes_repository.dart';
import '../../features/home/data/home_feed_store.dart';
import '../../features/home/full_screen_player_screen.dart';
import '../../features/home/sheets/comments_sheet.dart';
import '../../features/home/sheets/more_menu_sheet.dart';
import '../../features/playlists/data/playlists_store.dart';
import '../../features/playlists/data/season_providers.dart';
import '../../features/playlists/playlist_menu_sheet.dart';
import '../../features/profile/data/downloads_store.dart';
import '../../features/profile/data/library_store.dart';
import '../error_handling/error_display.dart';
import '../sheets/description_sheet.dart';
import '../sheets/share_sheet.dart';
import 'network_image.dart';

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
///
/// Like and save post to the real toggles (`POST /episodes/like` /
/// `/episodes/save`) via [feedEngagementProvider]: optimistic flip, rollback
/// and an error toast on failure. Counts are the payload's counts plus this
/// session's delta; when the source carried no count, no number is shown —
/// the rail used to render a hardcoded 120 under every icon.
///
/// Playback also feeds a throttled `POST /episodes/track-view` (about every
/// 10s plus a final post when the page changes), which is what keeps watch
/// history and continue-watching real. Telemetry failures stay silent.
class VideoFeedCard extends ConsumerStatefulWidget {
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
    this.onOpenEpisode,
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

  /// Called when the user picks another episode of this season out of the EP
  /// chip's sheet, and the card is inside a scrollable feed that can show it.
  ///
  /// Home passes a callback and the episode is opened *in the feed*. The
  /// subscriptions episode modal builds this same card with nothing behind it
  /// to scroll, so it leaves this null and the picked episode opens in the
  /// player modal instead.
  final ValueChanged<PlaylistEpisode>? onOpenEpisode;

  @override
  ConsumerState<VideoFeedCard> createState() => _VideoFeedCardState();
}

class _VideoFeedCardState extends ConsumerState<VideoFeedCard> {
  VideoPlayerController? _controller;
  var _ready = false;
  var _initFailed = false;

  /// Whether the user paused this card by tapping it, as opposed to it being
  /// paused because it scrolled off screen. Kept apart so scrolling back to a
  /// card the user paused does not silently resume it.
  var _userPaused = false;

  /// True while [FullScreenPlayerScreen] is using [_controller]. The feed
  /// must not pause/dispose it or mount a second [VideoPlayer] on top.
  var _playerHandedOff = false;

  ViewTracker? _viewTracker;

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
    _startViewTrackerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant VideoFeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldUrl = oldWidget.item?.videoUrl ?? oldWidget.videoUrl;
    final newUrl = _item.videoUrl;
    final oldType = oldWidget.item?.type ?? oldWidget.contentType;
    final newType = _item.type;
    final oldEpisodeId = oldWidget.item?.episodeId;
    if (oldUrl != newUrl || oldType != newType) {
      _disposeController();
      _startControllerIfNeeded();
    }
    if (oldEpisodeId != _item.episodeId) {
      _viewTracker?.dispose();
      _viewTracker = null;
      _startViewTrackerIfNeeded();
    }
    if (oldWidget.isActive != widget.isActive) {
      // Scrolling away ends the manual pause: coming back to a card should
      // play it, the way it would on first arrival. The flag only protects a
      // pause for as long as the user is looking at what they paused.
      if (!widget.isActive && _userPaused) _userPaused = false;
      _syncPlayPause();
      // Page swiped away — post the final position now, not in 10 seconds.
      if (!widget.isActive) _viewTracker?.flush();
    }
  }

  void _startViewTrackerIfNeeded() {
    final episodeId = _item.episodeId;
    if (episodeId == null || episodeId.isEmpty || !_item.hasPlayableVideo) {
      return;
    }
    final repository = ref.read(episodesRepositoryProvider);
    _viewTracker = ViewTracker(
      episodeId: episodeId,
      totalSeconds: _item.durationSeconds,
      post: (id, {required watchDurationSeconds, required completed}) =>
          repository.trackView(
            id,
            watchDurationSeconds: watchDurationSeconds,
            completed: completed,
          ),
    );
  }

  Future<void> _startControllerIfNeeded() async {
    if (!_item.hasPlayableVideo) return;
    final url = _item.videoUrl!;
    // Prefer a finished offline pack so Downloads (and any other surface that
    // opens this card) keep working with data off. Falls back to streaming.
    final episodeId = _item.episodeId;
    final localPath = episodeId == null
        ? null
        : ref.read(downloadsProvider.notifier).filePathFor(episodeId);
    final localFile = localPath != null ? File(localPath) : null;
    final useLocal = localFile != null && await localFile.exists();

    final controller = useLocal
        ? VideoPlayerController.file(localFile)
        : VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;
    controller.addListener(_onControllerTick);
    try {
      await controller.initialize();
      if (!mounted || _controller != controller) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      // await controller.setVolume(0); // Removed: feed autoplay muted without a toggle
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
    final c = _controller;
    if (c != null && c.value.isInitialized && c.value.isPlaying) {
      _viewTracker?.onProgress(c.value.position, c.value.duration);
    }
    // Rebuild for progress bar; VideoPlayer also paints via its own Texture.
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPlayPause();
  }

  void _syncPlayPause() {
    final c = _controller;
    if (c == null || !_ready) return;
    // Full screen owns the clock — pausing here would freeze FS mid-play.
    if (_playerHandedOff) return;
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
    if (widget.isActive && isCurrentRoute) {
      // A card the user paused by hand stays paused while it is on screen —
      // otherwise any rebuild (a tick, a like, a count change) would restart
      // playback under their finger.
      if (!c.value.isPlaying && !_userPaused) c.play();
    } else {
      if (c.value.isPlaying) c.pause();
    }
  }

  /// More menu → Full Screen: hand the live controller over so playback
  /// continues at the same timestamp (and resumes the same way on close).
  Future<void> _openMoreMenu(HomeFeedItem item, String? episodeId) async {
    final result = await showMoreMenuSheet(
      context,
      episodeId: episodeId,
      item: item,
    );
    if (!mounted || result != MoreMenuResult.fullScreen) return;

    final c = _controller;
    setState(() => _playerHandedOff = true);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => FullScreenPlayerScreen(
          item: item,
          sharedController: (c != null && c.value.isInitialized) ? c : null,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _playerHandedOff = false;
      // Mirror whatever pause state full screen left the shared player in.
      if (c != null && c.value.isInitialized) {
        _userPaused = !c.value.isPlaying;
      }
    });
    _syncPlayPause();
  }

  /// Tap-to-pause, the TikTok gesture: tap anywhere on the video to stop, tap
  /// again to resume. The paused state is deliberate, so it survives rebuilds
  /// and shows a play glyph — a silently frozen frame reads as a broken video.
  void _togglePlayPause() {
    final c = _controller;
    if (c == null || !_ready) return;
    setState(() {
      if (c.value.isPlaying) {
        c.pause();
        _userPaused = true;
      } else {
        c.play();
        _userPaused = false;
      }
    });
  }

  /// The EP chip: the season this episode belongs to, its siblings, and their
  /// lock state.
  ///
  /// The display hints come off the item so the sheet header reads correctly
  /// before `GET /seasons/{id}/episodes` returns; [SeasonArg] compares on id
  /// alone, so this shares a cache entry with the same season opened from a
  /// profile or a search result.
  Future<void> _openSeasonSheet(HomeFeedItem item) {
    final c = _controller;
    return showSeasonSheet(
      context,
      season: SeasonArg(
        id: item.seasonId!,
        title: item.seasonTitle,
        description: item.description,
        creatorName: item.creatorName,
        creatorId: item.creatorId,
        skillworld: item.skillworld,
      ),
      playingEpisodeId: item.episodeId,
      // The playing row's progress bar reads this card's actual clock. It used
      // to be a hardcoded 0.71 — a watch position the user had never reached.
      // Null while the controller is uninitialised, which draws no bar rather
      // than an invented one.
      playingProgress: (c != null && c.value.isInitialized)
          ? videoProgressFraction(c.value.position, c.value.duration)
          : null,
      onOpenInFeed: widget.onOpenEpisode,
    );
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
    _viewTracker?.dispose();
    _viewTracker = null;
    final c = _controller;
    _controller = null;
    c?.removeListener(_onControllerTick);
    // If full screen still holds the shared controller, disposing here would
    // kill mid-handoff. That only happens if the card is torn down under FS
    // (feed page disposed); FS then owns a disposed controller — rare. Prefer
    // disposing when we still own it so we do not leak on normal exits.
    if (!_playerHandedOff) c?.dispose();
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
    // Hide the feed [VideoPlayer] while full screen is using the same
    // controller — two attachments on one controller glitch on some devices.
    final showVideo =
        _ready && _controller != null && !_initFailed && !_playerHandedOff;

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
              SkifluxNetworkImage(
                url: item.coverUrl!,
                errorWidget: Image.asset(
                  item.coverAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Image.asset(
                    'assets/home_video_cover.png',
                    fit: BoxFit.cover,
                  ),
                ),
                // The cover sits under the video; a shimmer would flash behind
                // every card as the feed scrolls. The card's own brand fill is
                // the quieter placeholder.
                placeholder: const ColoredBox(
                  color: SkifluxColors.contentBrandInactive,
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
            // Explicitly transparent to pointers: it covers the whole card, so
            // anything it might absorb it would absorb everywhere.
            const IgnorePointer(
              child: DecoratedBox(
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
            ),
            // Tap-to-pause, over the media and the gradient but under the
            // chrome, so the whole frame answers a tap while the EP chip,
            // "View More" and the action rail keep their own.
            //
            // This started life wrapped around the video itself, several
            // layers down in the stack, and on the feed it never fired. A
            // dedicated fill layer at a known depth cannot be shadowed by
            // whatever gets stacked over the media next.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _togglePlayPause,
              ),
            ),
            if (progress != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _VideoProgressBar(progress: progress),
              ),
            // Paused-by-tap glyph. Ignores pointers so the tap that resumes
            // playback still reaches the video underneath.
            if (showVideo)
              IgnorePointer(
                child: _PausedOverlay(visible: _userPaused),
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
                            // A standalone episode has no season to list. The
                            // tag still reads as the episode number, but the
                            // chevron and the tap go away rather than opening
                            // an empty sheet.
                            onTap: item.hasSeason
                                ? () => _openSeasonSheet(item)
                                : null,
                            borderRadius: SkifluxRadii.borderPill,
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: SkifluxSpacing.spaceS,
                                right: item.hasSeason
                                    ? SkifluxSpacing.spaceXs
                                    : SkifluxSpacing.spaceS,
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
                                  if (item.hasSeason) ...[
                                    const SizedBox(
                                      width: SkifluxSpacing.space2xs,
                                    ),
                                    const Icon(
                                      RemixIcons.arrow_right_s_line,
                                      size: SkifluxSpacing.spaceM,
                                      color: SkifluxColors.contentBrand,
                                    ),
                                  ],
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
                  _ActionRail(
                    item: item,
                    onMoreTap: () => _openMoreMenu(
                      item,
                      item.episodeId?.isNotEmpty == true ? item.episodeId : null,
                    ),
                  ),
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

/// The TikTok pause glyph: a large translucent play triangle centred on the
/// video while it is paused by tap.
///
/// Without it a paused card is just a frozen frame, which reads as a video
/// that failed to load rather than one the user stopped. It fades and scales
/// in, and fades out on resume, so a deliberate tap gets a deliberate answer.
class _PausedOverlay extends StatelessWidget {
  const _PausedOverlay({required this.visible});

  final bool visible;

  /// Larger than any icon on the token scale — this is a full-screen playback
  /// affordance, not a control in a row.
  static const double _glyphSize = 72;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      child: AnimatedScale(
        scale: visible ? 1 : 0.8,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: const Center(
          child: Icon(
            RemixIcons.play_fill,
            size: _glyphSize,
            // Half-opaque white reads over both bright and dark frames without
            // a scrim behind it.
            color: Color(0x99FFFFFF),
          ),
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

class _ActionRail extends ConsumerWidget {
  const _ActionRail({required this.item, required this.onMoreTap});

  final HomeFeedItem item;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodeId = item.episodeId ?? '';
    final hasEpisode = episodeId.isNotEmpty;

    // Base state = membership in the loaded /me/liked / /me/saved pages
    // (`Episode` has counts but no is_liked/is_saved); session toggles win.
    final engagement = ref.watch(feedEngagementProvider)[episodeId];
    final likedList = ref.watch(likedEpisodesProvider).value;
    final savedList = ref.watch(savedEpisodesProvider).value;
    final baseLiked =
        hasEpisode && (likedList?.any((e) => e.id == episodeId) ?? false);
    final baseSaved =
        hasEpisode && (savedList?.any((e) => e.id == episodeId) ?? false);
    final liked = engagement?.liked ?? baseLiked;
    final saved = engagement?.saved ?? baseSaved;
    // Counts move by this session's net delta, never by comparing the toggle
    // against the refetched membership list — see [engagedCount].
    final likeDelta = engagement?.likeDelta ?? 0;
    final saveDelta = engagement?.saveDelta ?? 0;
    final commentDelta = engagement?.commentDelta ?? 0;

    Future<void> toggle(Future<bool> Function(String) action) async {
      try {
        await action(episodeId);
      } catch (e, st) {
        if (!context.mounted) return;
        await ErrorDisplay.show(context, ref, e, stackTrace: st);
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LikeButton(
          liked: liked,
          count: engagedCount(item.likeCount, likeDelta),
          onTap: hasEpisode
              ? () =>
                  toggle(ref.read(feedEngagementProvider.notifier).toggleLike)
              : null,
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        _ActionItem(
          icon: RemixIcons.chat_3_fill,
          count: _railCount(engagedCount(item.commentCount, commentDelta)),
          onTap: hasEpisode
              ? () => showCommentsSheet(context, episodeId)
              : null,
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        _ActionItem(
          icon: RemixIcons.bookmark_fill,
          iconColor: saved
              ? SkifluxColors.contentBrand
              : SkifluxColors.contentPrimaryInverse,
          count: _railCount(
            engagedCount(item.saveCount, saveDelta),
          ),
          onTap: hasEpisode
              ? () =>
                  toggle(ref.read(feedEngagementProvider.notifier).toggleSave)
              : null,
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        _ActionItem(
          icon: RemixIcons.share_forward_fill,
          // No share count exists on the Episode payload; show none.
          count: '',
          // The device's own share sheet. This used to open a custom row of
          // eight branded circles, none of which did anything.
          onTap: () => showShareSheet(
            context,
            title: item.creatorName.isEmpty
                ? item.title
                : '${item.title} — @${item.creatorUsername}',
            url: shareableMediaUrl(item.videoUrl),
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        GestureDetector(
          onTap: onMoreTap,
          child: const Icon(
            RemixIcons.more_fill,
            size: SkifluxUnit.u32,
            color: SkifluxColors.contentPrimaryInverse,
          ),
        ),
      ],
    );
  }

  /// Compact rail label; empty when the payload carried no count.
  static String _railCount(int? count) {
    if (count == null) return '';
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }
}

/// Like control — heart pops (elastic scale) and fills red when liked.
class _LikeButton extends StatefulWidget {
  const _LikeButton({required this.liked, required this.count, this.onTap});

  final bool liked;
  final int? count;
  final VoidCallback? onTap;

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

  @override
  void didUpdateWidget(covariant _LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.liked && widget.liked) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        children: [
          RepaintBoundary(
            child: ScaleTransition(
              scale: _scale,
              child: Icon(
                RemixIcons.heart_3_fill,
                size: SkifluxUnit.u32,
                color: widget.liked
                    ? SkifluxColors.contentNegative
                    : SkifluxColors.contentPrimaryInverse,
              ),
            ),
          ),
          if (widget.count != null) ...[
            const SizedBox(height: SkifluxSpacing.spaceXs),
            Text(
              _ActionRail._railCount(widget.count),
              style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                color: SkifluxColors.contentPrimaryInverse,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.count,
    this.onTap,
    this.iconColor = SkifluxColors.contentPrimaryInverse,
  });

  final IconData icon;
  final String count;
  final VoidCallback? onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: SkifluxUnit.u32, color: iconColor),
          if (count.isNotEmpty) ...[
            const SizedBox(height: SkifluxSpacing.spaceXs),
            Text(
              count,
              style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                color: SkifluxColors.contentPrimaryInverse,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
