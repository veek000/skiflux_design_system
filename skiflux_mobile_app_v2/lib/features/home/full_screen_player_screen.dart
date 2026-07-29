/// Figma: **Video Play Flow 4** (`3416:12683`) — the full-screen player,
/// opened from the More Menu's "Full Screen" row.
///
/// The frame keeps the phone in portrait and strips the player down to the
/// video itself: no EP chip, no title, no action rail. Only two controls
/// survive — close, and the playback-speed circle — over a white ground, with
/// the progress bar pinned to the bottom.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../playlists/data/playlists_store.dart';
import 'sheets/playback_speed_sheet.dart';

/// `3416:12703` centres a 393 × 654 frame rather than filling the screen, so
/// the video keeps that ratio instead of stretching to the device height.
const double _videoAspect = 393 / 654;

/// `3666:13547`: the brand fill runs 100 of the frame's 393pt.
const double _watchedFraction = 100 / 393;

/// `3416:12688` — the control discs are the 48px Main Avatar component with a
/// 24px glyph, which is `Unit/48`; the disc's own padding is Figma's 14.4.
const double _control = SkifluxUnit.u48;

class FullScreenPlayerScreen extends ConsumerWidget {
  const FullScreenPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(playerPrefsProvider);
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
                  // TODO(backend, blocking): replace local placeholder asset paths with real CDN/backend video thumbnail URLs — expects: String (network URL)
                  child: Image.asset(
                    'assets/home_video_raw1.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Image.asset(
                      'assets/home_video_cover.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            // `3416:12686` — controls sit in the white band above the video.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SkifluxSpacing.spaceL,
                ),
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
            // `3666:13547` — full-bleed progress bar on the bottom edge.
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _VideoProgress(),
            ),
          ],
        ),
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
  const _VideoProgress();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: SkifluxRadii.borderPill,
      child: const SizedBox(
        height: SkifluxSpacing.spaceXs,
        child: Stack(
          children: [
            ColoredBox(color: SkifluxColors.backgroundSelected),
            FractionallySizedBox(
              widthFactor: _watchedFraction,
              child: ColoredBox(color: SkifluxColors.contentBrand),
            ),
          ],
        ),
      ),
    );
  }
}
