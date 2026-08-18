/// Figma: **Video Play Flow 4** (`3416:12683`) — the full-screen player,
/// opened from the More Menu's "Full Screen" row.
///
/// The frame keeps the phone in portrait and strips the player down to the
/// video itself: no EP chip, no title, no action rail. Only two controls
/// survive — close, and the playback-speed circle — over a white ground, with
/// the progress bar pinned to the bottom.
///
/// It plays the episode it was opened for. Prefer [sharedController] from the
/// feed card so Full Screen continues at the same timestamp (TikTok-style);
/// without one it creates its own player (and used to always start at 0:00).
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';
import 'package:video_player/video_player.dart';

import '../../shared/widgets/network_image.dart';
import '../playlists/data/playlists_store.dart';
import '../profile/data/downloads_store.dart';
import 'data/home_feed_store.dart';
import 'sheets/playback_speed_sheet.dart';

/// `3416:12703` centres a 393 × 654 frame rather than filling the screen, so
/// the video keeps that ratio instead of stretching to the device height.
const double _videoAspect = 393 / 654;

/// `3416:12688` — the control discs are the 48px Main Avatar component with a
/// 24px glyph, which is `Unit/48`; the disc's own padding is Figma's 14.4.
const double _control = SkifluxUnit.u48;

class FullScreenPlayerScreen extends ConsumerStatefulWidget {
  const FullScreenPlayerScreen({
    super.key,
    this.item,
    this.sharedController,
  });

  /// The episode to play. Null only when opened without one, in which case the
  /// screen says so rather than showing a stock frame.
  final HomeFeedItem? item;

  /// Live controller from the feed card. When set, this screen does **not**
  /// create or dispose a player — it just attaches a [VideoPlayer] and keeps
  /// going from the current position. The feed reclaims it on pop.
  final VideoPlayerController? sharedController;

  @override
  ConsumerState<FullScreenPlayerScreen> createState() =>
      _FullScreenPlayerScreenState();
}

class _FullScreenPlayerScreenState
    extends ConsumerState<FullScreenPlayerScreen> {
  VideoPlayerController? _controller;
  var _ready = false;
  var _failed = false;
  var _ownsController = false;

  /// Paused by tapping the video, as in the feed.
  var _userPaused = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final shared = widget.sharedController;
    if (shared != null && shared.value.isInitialized) {
      // Seamless handoff: same clock, same buffer, no seek-to-zero.
      // The more-menu route usually paused the feed player — resume here so
      // opening Full Screen does not leave a frozen frame.
      _controller = shared;
      _ownsController = false;
      shared.addListener(_onTick);
      await shared.setPlaybackSpeed(ref.read(playerPrefsProvider).speed);
      if (!mounted) return;
      setState(() {
        _ready = true;
        _userPaused = false;
      });
      await shared.play();
      return;
    }

    final url = widget.item?.videoUrl;
    if (url == null || url.isEmpty) return;
    final episodeId = widget.item?.episodeId;
    final localPath = episodeId == null
        ? null
        : ref.read(downloadsProvider.notifier).filePathFor(episodeId);
    final localFile = localPath != null ? File(localPath) : null;
    final useLocal = localFile != null && await localFile.exists();
    final controller = useLocal
        ? VideoPlayerController.file(localFile)
        : VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;
    _ownsController = true;
    controller.addListener(_onTick);
    try {
      await controller.initialize();
      if (!mounted || _controller != controller) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setPlaybackSpeed(ref.read(playerPrefsProvider).speed);
      setState(() => _ready = true);
      await controller.play();
    } catch (error) {
      debugPrint('FullScreenPlayer: init failed for $url → $error');
      if (!mounted) return;
      await controller.dispose();
      if (_controller != controller) return;
      _controller = null;
      setState(() {
        _ready = false;
        _failed = true;
      });
    }
  }

  void _onTick() {
    // Drives the progress bar; the texture paints itself.
    if (mounted) setState(() {});
  }

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

  @override
  void dispose() {
    final c = _controller;
    _controller = null;
    c?.removeListener(_onTick);
    // Never dispose a borrowed feed controller — the card still owns it.
    if (_ownsController) c?.dispose();
    super.dispose();
  }

  /// Elapsed fraction from the real clock, 0 until the controller is ready.
  double get _progress {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return 0;
    return videoProgressFraction(c.value.position, c.value.duration);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(playerPrefsProvider);
    // A speed picked from the sheet while this screen is open applies to the
    // controller it owns, not just to the next one created.
    final c = _controller;
    if (c != null && _ready && c.value.playbackSpeed != prefs.speed) {
      c.setPlaybackSpeed(prefs.speed);
    }

    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _videoAspect,
                child: ColoredBox(
                  // Same base fill the feed card uses behind the cover.
                  color: SkifluxColors.contentBrandInactive,
                  child: _stage(),
                ),
              ),
            ),
            // `3416:12686` — controls sit in the white band above the video.
            // Inset by `spaceL`, so the discs land on the same baseline as the
            // home screen's search / bell row (also `SafeArea` + `spaceL`).
            // They used to be flush against the top edge, which read as too
            // high next to every other screen in the app.
            Positioned(
              top: SkifluxSpacing.spaceL,
              left: SkifluxSpacing.spaceL,
              right: SkifluxSpacing.spaceL,
              child: SizedBox(
                height: SkifluxUnit.u48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ControlDisc(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        RemixIcons.close_fill,
                        size: SkifluxIcons.sizeM,
                        color: SkifluxColors.contentPrimary,
                      ),
                    ),
                    _ControlDisc(
                      onTap: () => showPlaybackSpeedSheet(context),
                      child: Text(
                        prefs.speedLabelShort,
                        style: SkifluxTypography.headingH9Bold.copyWith(
                          color: SkifluxColors.contentPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // `3666:13547` — full-bleed progress bar on the bottom edge, from
            // the real clock rather than a fixed fraction.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _VideoProgress(progress: _progress),
            ),
          ],
        ),
      ),
    );
  }

  /// The video, or an honest stand-in for it.
  Widget _stage() {
    final item = widget.item;
    final c = _controller;

    if (_ready && c != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _togglePlayPause,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            ),
            if (_userPaused)
              const IgnorePointer(
                child: Center(
                  child: Icon(
                    RemixIcons.play_fill,
                    size: 72,
                    color: Color(0x99FFFFFF),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // No video yet, or it failed: this episode's own cover, never a bundled
    // stock frame.
    final cover = item?.coverUrl;
    if (cover != null && cover.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          SkifluxNetworkImage(url: cover),
          if (!_failed && (item?.hasPlayableVideo ?? false))
            const Center(child: SkifluxSpinner()),
        ],
      );
    }
    return Center(
      child: Icon(
        _failed ? RemixIcons.error_warning_line : RemixIcons.film_line,
        size: SkifluxIcons.sizeL,
        color: SkifluxColors.contentPrimaryInverse,
      ),
    );
  }
}

/// The 48px `Background/Hover` disc both controls share.
class _ControlDisc extends StatelessWidget {
  const _ControlDisc({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SkifluxColors.backgroundHover,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: _control,
          height: _control,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _VideoProgress extends StatelessWidget {
  const _VideoProgress({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: SkifluxRadii.borderPill,
      child: SizedBox(
        height: SkifluxSpacing.spaceXs,
        child: Stack(
          children: [
            const ColoredBox(color: SkifluxColors.backgroundSelected),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: const ColoredBox(color: SkifluxColors.contentBrand),
            ),
          ],
        ),
      ),
    );
  }
}
