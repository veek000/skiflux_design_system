/// Disk-and-memory-cached remote images.
///
/// Every thumbnail and avatar in the app used a bare `Image.network`, which
/// caches in memory only and for as long as the widget lives. Scrolling a rail
/// away and back refetched the same bytes over the network — visible as a
/// re-flash on every rebuild, and paid for again on mobile data.
/// [CachedNetworkImage] keeps them on disk between launches.
///
/// This wrapper exists so the placeholder and error behaviour is decided once:
/// a shimmer while loading (matching the skeletons the rest of the app uses),
/// and a caller-supplied fallback on failure, because what a broken image
/// should become differs by surface — a stock cover on a video card, a flat
/// fill in a search row.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

class SkifluxNetworkImage extends StatelessWidget {
  const SkifluxNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
    this.placeholder,
    this.borderRadius,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// Drawn when the fetch or decode fails. Defaults to a flat disabled fill —
  /// pass an asset image where the surface has a designed fallback.
  final Widget? errorWidget;

  /// Drawn while loading. Defaults to the shimmer skeleton.
  final Widget? placeholder;

  /// Rounds the image (and its placeholder/error states with it), so callers
  /// don't need their own [ClipRRect] just to keep the corners consistent.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    Widget image = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      // `radius: 0` — the shimmer fills whatever box it is given; rounding is
      // applied once, below, so it matches the image exactly.
      placeholder: (_, _) => placeholder ?? const SkifluxSkeleton(radius: 0),
      errorWidget: (_, _, _) =>
          errorWidget ??
          const ColoredBox(color: SkifluxColors.backgroundDisabled),
      // Cross-fade on a cache hit reads as a flicker, not a transition.
      fadeInDuration: const Duration(milliseconds: 150),
      fadeOutDuration: Duration.zero,
    );
    final radius = borderRadius;
    if (radius != null) {
      image = ClipRRect(borderRadius: radius, child: image);
    }
    return image;
  }
}

/// [ImageProvider] form, for the places that need one rather than a widget —
/// [SkifluxAvatar.image], [DecorationImage], and so on.
///
/// Shares the same disk cache as [SkifluxNetworkImage], so an avatar fetched
/// for a comment row is already local when the same person appears on the
/// leaderboard.
ImageProvider skifluxImageProvider(String url) =>
    CachedNetworkImageProvider(url);
